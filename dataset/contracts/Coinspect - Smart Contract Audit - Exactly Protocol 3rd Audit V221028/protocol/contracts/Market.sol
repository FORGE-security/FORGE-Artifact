// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC4626, ERC20, SafeTransferLib } from "solmate/src/mixins/ERC4626.sol";
import { InterestRateModel } from "./InterestRateModel.sol";
import { FixedLib } from "./utils/FixedLib.sol";
import { Auditor } from "./Auditor.sol";

contract Market is Initializable, AccessControlUpgradeable, PausableUpgradeable, ERC4626 {
  using FixedPointMathLib for int256;
  using FixedPointMathLib for uint256;
  using FixedPointMathLib for uint128;
  using SafeTransferLib for ERC20;
  using FixedLib for FixedLib.Pool;
  using FixedLib for FixedLib.Position;
  using FixedLib for uint256;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
  Auditor public immutable auditor;

  mapping(uint256 => mapping(address => FixedLib.Position)) public fixedDepositPositions;
  mapping(uint256 => mapping(address => FixedLib.Position)) public fixedBorrowPositions;
  mapping(address => uint256) public floatingBorrowShares;

  mapping(address => uint256) public fixedBorrows;
  mapping(address => uint256) public fixedDeposits;
  mapping(uint256 => FixedLib.Pool) public fixedPools;

  uint256 public floatingBackupBorrowed;
  uint256 public floatingDebt;

  uint256 public earningsAccumulator;
  uint256 public penaltyRate;
  uint256 public backupFeeRate;
  uint256 public dampSpeedUp;
  uint256 public dampSpeedDown;

  uint8 public maxFuturePools;
  uint32 public lastAccumulatorAccrual;
  uint32 public lastFloatingDebtUpdate;
  uint32 public lastAverageUpdate;

  InterestRateModel public interestRateModel;

  uint128 public earningsAccumulatorSmoothFactor;
  uint128 public reserveFactor;

  uint256 public floatingAssets;
  uint256 public floatingAssetsAverage;

  uint256 public totalFloatingBorrowShares;
  uint256 public floatingUtilization;

  address public treasury;
  uint256 public treasuryFeeRate;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(ERC20 asset_, Auditor auditor_) ERC4626(asset_, "", "") {
    auditor = auditor_;

    _disableInitializers();
  }

  function initialize(
    uint8 maxFuturePools_,
    uint128 earningsAccumulatorSmoothFactor_,
    InterestRateModel interestRateModel_,
    uint256 penaltyRate_,
    uint256 backupFeeRate_,
    uint128 reserveFactor_,
    uint256 dampSpeedUp_,
    uint256 dampSpeedDown_
  ) external initializer {
    __AccessControl_init();
    __Pausable_init();

    string memory assetSymbol = asset.symbol();
    name = string.concat("EToken", assetSymbol);
    symbol = string.concat("e", assetSymbol);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    setMaxFuturePools(maxFuturePools_);
    setEarningsAccumulatorSmoothFactor(earningsAccumulatorSmoothFactor_);
    setInterestRateModel(interestRateModel_);
    setPenaltyRate(penaltyRate_);
    setBackupFeeRate(backupFeeRate_);
    setReserveFactor(reserveFactor_);
    setDampSpeed(dampSpeedUp_, dampSpeedDown_);
  }

  /// @notice Borrows a certain amount from the floating pool.
  /// @param assets amount to be sent to receiver and repaid by borrower.
  /// @param receiver address that will receive the borrowed assets.
  /// @param borrower address that will repay the borrowed assets.
  /// @return borrowShares shares corresponding to the borrowed assets.
  function borrow(
    uint256 assets,
    address receiver,
    address borrower
  ) external whenNotPaused returns (uint256 borrowShares) {
    checkAllowance(borrower, assets);

    updateFloatingDebt();

    borrowShares = previewBorrow(assets);

    uint256 newFloatingDebt = floatingDebt + assets;
    floatingDebt = newFloatingDebt;
    // check if the underlying liquidity that the account wants to withdraw is borrowed, also considering the reserves
    if (floatingBackupBorrowed + newFloatingDebt > floatingAssets.mulWadDown(1e18 - reserveFactor)) {
      revert InsufficientProtocolLiquidity();
    }

    totalFloatingBorrowShares += borrowShares;
    floatingBorrowShares[borrower] += borrowShares;

    emit Borrow(msg.sender, receiver, borrower, assets, borrowShares);
    emitMarketUpdate();

    auditor.checkBorrow(this, borrower);
    asset.safeTransfer(receiver, assets);
  }

  /// @notice Repays a certain amount of assets to the floating pool.
  /// @param assets assets to be subtracted from the borrower's accountability.
  /// @param borrower address of the account that has the debt.
  /// @return actualRepay the actual amount that should be transferred into the protocol.
  /// @return borrowShares subtracted shares from the borrower's accountability.
  function repay(uint256 assets, address borrower)
    external
    whenNotPaused
    returns (uint256 actualRepay, uint256 borrowShares)
  {
    borrowShares = previewRepay(assets);
    actualRepay = noTransferRefund(borrowShares, borrower);
    emitMarketUpdate();
    asset.safeTransferFrom(msg.sender, address(this), actualRepay);
  }

  /// @notice Repays a certain amount of shares to the floating pool.
  /// @param borrowShares shares to be subtracted from the borrower's accountability.
  /// @param borrower address of the account that has the debt.
  /// @return assets subtracted assets from the borrower's accountability.
  function refund(uint256 borrowShares, address borrower) external whenNotPaused returns (uint256 assets) {
    assets = noTransferRefund(borrowShares, borrower);
    emitMarketUpdate();
    asset.safeTransferFrom(msg.sender, address(this), assets);
  }

  /// @notice Allows to (partially) repay a floating borrow. It does not transfer assets.
  /// @param borrowShares shares to be subtracted from the borrower's accountability.
  /// @param borrower the address of the account that has the debt.
  /// @return assets the actual amount that should be transferred into the protocol.
  function noTransferRefund(uint256 borrowShares, address borrower) internal returns (uint256 assets) {
    updateFloatingDebt();
    uint256 userBorrowShares = floatingBorrowShares[borrower];
    borrowShares = Math.min(borrowShares, userBorrowShares);
    assets = previewRefund(borrowShares);

    if (assets == 0) revert ZeroRepay();

    floatingDebt -= assets;
    floatingBorrowShares[borrower] = userBorrowShares - borrowShares;
    totalFloatingBorrowShares -= borrowShares;

    emit Repay(msg.sender, borrower, assets, borrowShares);
  }

  /// @notice Deposits a certain amount to a maturity.
  /// @param maturity maturity date where the assets will be deposited.
  /// @param assets amount to receive from the msg.sender.
  /// @param minAssetsRequired minimum amount of assets required by the depositor for the transaction to be accepted.
  /// @param receiver address that will be able to withdraw the deposited assets.
  /// @return positionAssets total amount of assets (principal + fee) to be withdrawn at maturity.
  function depositAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 minAssetsRequired,
    address receiver
  ) external whenNotPaused returns (uint256 positionAssets) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.NONE);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    (uint256 fee, uint256 backupFee) = pool.calculateDeposit(assets, backupFeeRate);
    positionAssets = assets + fee;
    if (positionAssets < minAssetsRequired) revert Disagreement();

    floatingBackupBorrowed -= pool.deposit(assets);
    pool.unassignedEarnings -= fee + backupFee;
    earningsAccumulator += backupFee;

    // update account's position
    FixedLib.Position storage position = fixedDepositPositions[maturity][receiver];

    // if account doesn't have a current position, add it to the list
    if (position.principal == 0) fixedDeposits[receiver] = fixedDeposits[receiver].setMaturity(maturity);

    fixedDepositPositions[maturity][receiver] = FixedLib.Position(position.principal + assets, position.fee + fee);

    floatingAssets += backupEarnings;

    emit DepositAtMaturity(maturity, msg.sender, receiver, assets, fee);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    asset.safeTransferFrom(msg.sender, address(this), assets);
  }

  /// @notice Borrows a certain amount from a maturity.
  /// @param maturity maturity date for repayment.
  /// @param assets amount to be sent to receiver and repaid by borrower.
  /// @param maxAssets maximum amount of debt that the account is willing to accept.
  /// @param receiver address that will receive the borrowed assets.
  /// @param borrower address that will repay the borrowed assets.
  /// @return assetsOwed total amount of assets (principal + fee) to be repaid at maturity.
  function borrowAtMaturity(
    uint256 maturity,
    uint256 assets,
    uint256 maxAssets,
    address receiver,
    address borrower
  ) external whenNotPaused returns (uint256 assetsOwed) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.NONE);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    updateFloatingAssetsAverage();
    uint256 fee = assets.mulWadDown(
      interestRateModel.fixedBorrowRate(maturity, assets, pool.borrowed, pool.supplied, floatingAssetsAverage)
    );
    assetsOwed = assets + fee;

    {
      uint256 memFloatingBackupBorrowed = floatingBackupBorrowed;
      memFloatingBackupBorrowed += pool.borrow(assets);
      floatingBackupBorrowed = memFloatingBackupBorrowed;
      if (memFloatingBackupBorrowed + floatingDebt > floatingAssets.mulWadDown(1e18 - reserveFactor)) {
        revert InsufficientProtocolLiquidity();
      }
    }

    // validate that the account is not taking arbitrary fees
    if (assetsOwed > maxAssets) revert Disagreement();

    checkAllowance(borrower, assetsOwed);

    {
      // if account doesn't have a current position, add it to the list
      FixedLib.Position storage position = fixedBorrowPositions[maturity][borrower];
      if (position.principal == 0) fixedBorrows[borrower] = fixedBorrows[borrower].setMaturity(maturity);

      // calculate what portion of the fees are to be accrued and what portion goes to earnings accumulator
      (uint256 newUnassignedEarnings, uint256 newBackupEarnings) = pool.distributeEarnings(
        chargeTreasuryFee(fee),
        assets
      );
      pool.unassignedEarnings += newUnassignedEarnings;
      collectFreeLunch(newBackupEarnings);

      fixedBorrowPositions[maturity][borrower] = FixedLib.Position(position.principal + assets, position.fee + fee);
    }

    floatingAssets += backupEarnings;

    emit BorrowAtMaturity(maturity, msg.sender, receiver, borrower, assets, fee);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    auditor.checkBorrow(this, borrower);
    asset.safeTransfer(receiver, assets);
  }

  /// @notice Withdraws a certain amount from a maturity.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// @param maturity maturity date where the assets will be withdrawn.
  /// @param positionAssets the amount of assets (principal + fee) to be withdrawn.
  /// @param minAssetsRequired minimum amount required by the account (if discount included for early withdrawal).
  /// @param receiver address that will receive the withdrawn assets.
  /// @param owner address that previously deposited the assets.
  /// @return assetsDiscounted amount of assets withdrawn (can include a discount for early withdraw).
  function withdrawAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 minAssetsRequired,
    address receiver,
    address owner
  ) external returns (uint256 assetsDiscounted) {
    if (positionAssets == 0) revert ZeroWithdraw();
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.MATURED);

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    FixedLib.Position memory position = fixedDepositPositions[maturity][owner];

    if (positionAssets > position.principal + position.fee) positionAssets = position.principal + position.fee;

    // verify if there are any penalties/fee for him because of early withdrawal - if so: discount
    if (block.timestamp < maturity) {
      updateFloatingAssetsAverage();
      assetsDiscounted = positionAssets.divWadDown(
        1e18 +
          interestRateModel.fixedBorrowRate(
            maturity,
            positionAssets,
            pool.borrowed,
            pool.supplied,
            floatingAssetsAverage
          )
      );
    } else {
      assetsDiscounted = positionAssets;
    }

    if (assetsDiscounted < minAssetsRequired) revert Disagreement();

    checkAllowance(owner, assetsDiscounted);

    // remove the supply from the fixed rate pool
    floatingBackupBorrowed += pool.withdraw(
      FixedLib.Position(position.principal, position.fee).scaleProportionally(positionAssets).principal
    );
    if (floatingBackupBorrowed + floatingDebt > floatingAssets) revert InsufficientProtocolLiquidity();

    // All the fees go to unassigned or to the floating pool
    (uint256 unassignedEarnings, uint256 newBackupEarnings) = pool.distributeEarnings(
      chargeTreasuryFee(positionAssets - assetsDiscounted),
      assetsDiscounted
    );
    pool.unassignedEarnings += unassignedEarnings;
    collectFreeLunch(newBackupEarnings);

    // the account gets discounted the full amount
    position.reduceProportionally(positionAssets);
    if (position.principal + position.fee == 0) {
      delete fixedDepositPositions[maturity][owner];
      fixedDeposits[owner] = fixedDeposits[owner].clearMaturity(maturity);
    } else {
      // proportionally reduce the values
      fixedDepositPositions[maturity][owner] = position;
    }

    floatingAssets += backupEarnings;

    emit WithdrawAtMaturity(maturity, msg.sender, receiver, owner, positionAssets, assetsDiscounted);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);

    asset.safeTransfer(receiver, assetsDiscounted);
  }

  /// @notice Repays a certain amount to a maturity.
  /// @param maturity maturity date where the assets will be repaid.
  /// @param positionAssets amount to be paid for the borrower's debt.
  /// @param maxAssets maximum amount of debt that the account is willing to accept to be repaid.
  /// @param borrower address of the account that has the debt.
  /// @return actualRepayAssets the actual amount that was transferred into the protocol.
  function repayAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 maxAssets,
    address borrower
  ) external whenNotPaused returns (uint256 actualRepayAssets) {
    // reverts on failure
    FixedLib.checkPoolState(maturity, maxFuturePools, FixedLib.State.VALID, FixedLib.State.MATURED);

    actualRepayAssets = noTransferRepayAtMaturity(maturity, positionAssets, maxAssets, borrower, true);
    asset.safeTransferFrom(msg.sender, address(this), actualRepayAssets);
  }

  /// @notice Allows to (partially) repay a fixed rate position. It does not transfer assets.
  /// @param maturity the maturity to access the pool.
  /// @param positionAssets the amount of debt of the pool that should be paid.
  /// @param maxAssets maximum amount of debt that the account is willing to accept to be repaid.
  /// @param borrower the address of the account that has the debt.
  /// @param canDiscount should early repay discounts be applied.
  /// @return actualRepayAssets the actual amount that should be transferred into the protocol.
  function noTransferRepayAtMaturity(
    uint256 maturity,
    uint256 positionAssets,
    uint256 maxAssets,
    address borrower,
    bool canDiscount
  ) internal returns (uint256 actualRepayAssets) {
    if (positionAssets == 0) revert ZeroRepay();

    FixedLib.Pool storage pool = fixedPools[maturity];

    uint256 backupEarnings = pool.accrueEarnings(maturity);

    FixedLib.Position memory position = fixedBorrowPositions[maturity][borrower];

    uint256 debtCovered = Math.min(positionAssets, position.principal + position.fee);

    uint256 principalCovered = FixedLib
      .Position(position.principal, position.fee)
      .scaleProportionally(debtCovered)
      .principal;

    // early repayment allows a discount from the unassigned earnings
    if (block.timestamp < maturity) {
      if (canDiscount) {
        // calculate the deposit fee considering the amount of debt the account'll pay
        (uint256 discountFee, uint256 backupFee) = pool.calculateDeposit(principalCovered, backupFeeRate);

        // remove the fee from unassigned earnings
        pool.unassignedEarnings -= discountFee + backupFee;

        // The fee charged to the MP supplier go to the earnings accumulator
        earningsAccumulator += backupFee;

        // The fee gets discounted from the account through `repayAmount`
        actualRepayAssets = debtCovered - discountFee;
      } else {
        actualRepayAssets = debtCovered;
      }
    } else {
      actualRepayAssets = debtCovered + debtCovered.mulWadDown((block.timestamp - maturity) * penaltyRate);

      // All penalties go to the earnings accumulator
      earningsAccumulator += actualRepayAssets - debtCovered;
    }

    // verify that the account agrees to this discount or penalty
    if (actualRepayAssets > maxAssets) revert Disagreement();

    // reduce the borrowed and might decrease the SP debt
    floatingBackupBorrowed -= pool.repay(principalCovered);

    // update the account position
    position.reduceProportionally(debtCovered);
    if (position.principal + position.fee == 0) {
      delete fixedBorrowPositions[maturity][borrower];
      fixedBorrows[borrower] = fixedBorrows[borrower].clearMaturity(maturity);
    } else {
      // proportionally reduce the values
      fixedBorrowPositions[maturity][borrower] = position;
    }

    floatingAssets += backupEarnings;

    emit RepayAtMaturity(maturity, msg.sender, borrower, actualRepayAssets, debtCovered);
    emitMarketUpdate();
    emitFixedEarningsUpdate(maturity);
  }

  /// @notice Liquidates undercollateralized position(s).
  /// @dev Msg.sender liquidates borrower's position(s) and repays a certain amount of debt for multiple maturities,
  /// seizing a part of borrower's collateral.
  /// @param borrower wallet that has an outstanding debt across all maturities.
  /// @param maxAssets maximum amount of debt that the liquidator is willing to accept. (it can be less)
  /// @param seizeMarket market from which the collateral will be seized to give the liquidator.
  /// @return repaidAssets actual amount repaid.
  function liquidate(
    address borrower,
    uint256 maxAssets,
    Market seizeMarket
  ) external whenNotPaused returns (uint256 repaidAssets) {
    if (msg.sender == borrower) revert SelfLiquidation();

    maxAssets = auditor.checkLiquidation(this, seizeMarket, borrower, maxAssets);
    if (maxAssets == 0) revert ZeroRepay();

    uint256 packedMaturities = fixedBorrows[borrower];
    uint256 baseMaturity = packedMaturities % (1 << 32);
    packedMaturities = packedMaturities >> 32;
    for (uint256 i = 0; i < 224; ) {
      if ((packedMaturities & (1 << i)) != 0) {
        uint256 maturity = baseMaturity + (i * FixedLib.INTERVAL);
        uint256 actualRepay;
        if (block.timestamp < maturity) {
          actualRepay = noTransferRepayAtMaturity(maturity, maxAssets, maxAssets, borrower, false);
          maxAssets -= actualRepay;
        } else {
          uint256 position;
          {
            FixedLib.Position storage p = fixedBorrowPositions[maturity][borrower];
            position = p.principal + p.fee;
          }
          uint256 debt = position + position.mulWadDown((block.timestamp - maturity) * penaltyRate);
          actualRepay = debt > maxAssets ? maxAssets.mulDivDown(position, debt) : maxAssets;

          if (actualRepay == 0) maxAssets = 0;
          else {
            actualRepay = noTransferRepayAtMaturity(maturity, actualRepay, maxAssets, borrower, false);
            maxAssets -= actualRepay;
            {
              FixedLib.Position storage p = fixedBorrowPositions[maturity][borrower];
              position = p.principal + p.fee;
            }
            debt = position + position.mulWadDown((block.timestamp - maturity) * penaltyRate);
            if ((debt > maxAssets ? maxAssets.mulDivDown(position, debt) : maxAssets) == 0) maxAssets = 0;
          }
        }
        repaidAssets += actualRepay;
      }

      unchecked {
        ++i;
      }
      if ((1 << i) > packedMaturities || maxAssets == 0) break;
    }

    if (maxAssets > 0 && floatingBorrowShares[borrower] > 0) {
      uint256 borrowShares = previewRepay(maxAssets);
      if (borrowShares > 0) {
        uint256 actualRepayAssets = noTransferRefund(borrowShares, borrower);
        emitMarketUpdate();
        repaidAssets += actualRepayAssets;
      }
    }

    // reverts on failure
    (uint256 lendersAssets, uint256 seizeAssets) = auditor.calculateSeize(this, seizeMarket, borrower, repaidAssets);
    floatingAssets += lendersAssets;

    if (address(seizeMarket) == address(this)) internalSeize(this, msg.sender, borrower, seizeAssets);
    else seizeMarket.seize(msg.sender, borrower, seizeAssets);

    emit Liquidate(msg.sender, borrower, repaidAssets, lendersAssets, seizeMarket, seizeAssets);

    auditor.handleBadDebt(borrower);

    asset.safeTransferFrom(msg.sender, address(this), repaidAssets + lendersAssets);
  }

  /// @notice Clears floating and fixed debt for an account spreading the losses between the floating assets.
  /// @dev Can only be called from the auditor.
  /// @param account account with insufficient collateral to be cleared the debt.
  function clearBadDebt(address account) external {
    if (msg.sender != address(auditor)) revert NotAuditor();

    uint256 packedMaturities = fixedBorrows[account];
    uint256 baseMaturity = packedMaturities % (1 << 32);
    packedMaturities = packedMaturities >> 32;
    for (uint256 i = 0; i < 224; ) {
      if ((packedMaturities & (1 << i)) != 0) {
        uint256 maturity = baseMaturity + (i * FixedLib.INTERVAL);

        FixedLib.Position storage position = fixedBorrowPositions[maturity][account];
        uint256 badDebt = position.principal + position.fee;
        if (badDebt > 0) {
          floatingBackupBorrowed -= fixedPools[maturity].repay(position.principal);
          delete fixedBorrowPositions[maturity][account];
          fixedBorrows[account] = fixedBorrows[account].clearMaturity(maturity);

          emit RepayAtMaturity(maturity, msg.sender, account, badDebt, badDebt);
          spreadBadDebt(badDebt);
        }
      }

      unchecked {
        ++i;
      }
      if ((1 << i) > packedMaturities) break;
    }
    uint256 borrowShares = floatingBorrowShares[account];
    if (borrowShares > 0) {
      uint256 badDebt = noTransferRefund(borrowShares, account);
      spreadBadDebt(badDebt);
    }
  }

  /// @notice Spreads bad debt subtracting the amount from the `earningsAccumulator` and/or `floatingAssets`.
  /// @param badDebt amount that it's assumed an account won't repay due to insufficient collateral.
  function spreadBadDebt(uint256 badDebt) internal {
    uint256 memEarningsAccumulator = earningsAccumulator;
    uint256 fromAccumulator = Math.min(memEarningsAccumulator, badDebt);
    earningsAccumulator = memEarningsAccumulator - fromAccumulator;
    if (fromAccumulator < badDebt) floatingAssets -= badDebt - fromAccumulator;

    emitMarketUpdate();
  }

  /// @notice Public function to seize a certain amount of assets.
  /// @dev Public function for liquidator to seize borrowers assets in the floating pool.
  /// This function will only be called from another Market, on `liquidation` calls.
  /// That's why msg.sender needs to be passed to the private function (to be validated as a market)
  /// @param liquidator address which will receive the seized assets.
  /// @param borrower address from which the assets will be seized.
  /// @param assets amount to be removed from borrower's possession.
  function seize(
    address liquidator,
    address borrower,
    uint256 assets
  ) external whenNotPaused {
    internalSeize(Market(msg.sender), liquidator, borrower, assets);
  }

  /// @notice Internal function to seize a certain amount of assets.
  /// @dev Internal function for liquidator to seize borrowers assets in the floating pool.
  /// Will only be called from this Market on `liquidation` or through `seize` calls from another Market.
  /// That's why msg.sender needs to be passed to the internal function (to be validated as a market).
  /// @param seizeMarket address which is calling the seize function (see `seize` public function).
  /// @param liquidator address which will receive the seized assets.
  /// @param borrower address from which the assets will be seized.
  /// @param assets amount to be removed from borrower's possession.
  function internalSeize(
    Market seizeMarket,
    address liquidator,
    address borrower,
    uint256 assets
  ) internal {
    if (assets == 0) revert ZeroWithdraw();

    // reverts on failure
    auditor.checkSeize(seizeMarket, this);

    uint256 shares = previewWithdraw(assets);
    beforeWithdraw(assets, shares);
    _burn(borrower, shares);
    emit Withdraw(msg.sender, liquidator, borrower, assets, shares);
    emit Seize(liquidator, borrower, assets);
    emitMarketUpdate();

    asset.safeTransfer(liquidator, assets);
  }

  /// @notice Hook to update the floating pool average, floating pool balance and distribute earnings from accumulator.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// @param assets amount of assets to be withdrawn from the floating pool.
  function beforeWithdraw(uint256 assets, uint256) internal override {
    updateFloatingAssetsAverage();
    updateFloatingDebt();
    uint256 earnings = accrueAccumulatedEarnings();
    uint256 newFloatingAssets = floatingAssets + earnings - assets;
    floatingAssets = newFloatingAssets;
    // check if the underlying liquidity that the account wants to withdraw is borrowed
    if (floatingBackupBorrowed + floatingDebt > newFloatingAssets) revert InsufficientProtocolLiquidity();
  }

  /// @notice Hook to update the floating pool average, floating pool balance and distribute earnings from accumulator.
  /// @param assets amount of assets to be deposited to the floating pool.
  function afterDeposit(uint256 assets, uint256) internal override whenNotPaused {
    updateFloatingAssetsAverage();
    updateFloatingDebt();
    uint256 earnings = accrueAccumulatedEarnings();
    floatingAssets += earnings + assets;
    emitMarketUpdate();
  }

  /// @notice Withdraws the owner's floating pool assets to the receiver address.
  /// @dev Makes sure that the owner doesn't have shortfall after withdrawing.
  /// @param assets amount of underlying to be withdrawn.
  /// @param receiver address to which the assets will be transferred.
  /// @param owner address which owns the floating pool assets.
  /// @return shares amount of shares redeemed for underlying asset.
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public override returns (uint256 shares) {
    auditor.checkShortfall(this, owner, assets);
    shares = super.withdraw(assets, receiver, owner);
    emitMarketUpdate();
  }

  /// @notice Redeems the owner's floating pool assets to the receiver address.
  /// @dev Makes sure that the owner doesn't have shortfall after withdrawing.
  /// @param shares amount of shares to be redeemed for underlying asset.
  /// @param receiver address to which the assets will be transferred.
  /// @param owner address which owns the floating pool assets.
  /// @return assets amount of underlying asset that was withdrawn.
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override returns (uint256 assets) {
    auditor.checkShortfall(this, owner, previewMint(shares));
    assets = super.redeem(shares, receiver, owner);
    emitMarketUpdate();
  }

  /// @notice Moves amount of shares from the caller's account to `to`.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// Makes sure that the caller doesn't have shortfall after transferring.
  /// @param to address to which the assets will be transferred.
  /// @param shares amount of shares to be transferred.
  function transfer(address to, uint256 shares) public override returns (bool) {
    auditor.checkShortfall(this, msg.sender, previewMint(shares));
    return super.transfer(to, shares);
  }

  /// @notice Moves amount of shares from `from` to `to` using the allowance mechanism.
  /// @dev It's expected that this function can't be paused to prevent freezing account funds.
  /// Makes sure that `from` address doesn't have shortfall after transferring.
  /// @param from address from which the assets will be transferred.
  /// @param to address to which the assets will be transferred.
  /// @param shares amount of shares to be transferred.
  function transferFrom(
    address from,
    address to,
    uint256 shares
  ) public override returns (bool) {
    auditor.checkShortfall(this, from, previewMint(shares));
    return super.transferFrom(from, to, shares);
  }

  /// @notice Gets current snapshot for an account across all maturities.
  /// @param account account to return status snapshot in the specified maturity date.
  /// @return the amount the account deposited to the floating pool and the total money it owes from maturities.
  function accountSnapshot(address account) external view returns (uint256, uint256) {
    return (convertToAssets(balanceOf[account]), previewDebt(account));
  }

  /// @notice Gets all borrows and penalties for an account.
  /// @param account account to return status snapshot for fixed and floating borrows.
  /// @return debt the total debt, denominated in number of assets.
  function previewDebt(address account) public view returns (uint256 debt) {
    uint256 memPenaltyRate = penaltyRate;
    uint256 packedMaturities = fixedBorrows[account];
    uint256 baseMaturity = packedMaturities % (1 << 32);
    packedMaturities = packedMaturities >> 32;
    // calculate all maturities using the baseMaturity and the following bits representing the following intervals
    for (uint256 i = 0; i < 224; ) {
      if ((packedMaturities & (1 << i)) != 0) {
        uint256 maturity = baseMaturity + (i * FixedLib.INTERVAL);
        FixedLib.Position storage position = fixedBorrowPositions[maturity][account];
        uint256 positionAssets = position.principal + position.fee;

        debt += positionAssets;

        uint256 secondsDelayed = FixedLib.secondsPre(maturity, block.timestamp);
        if (secondsDelayed > 0) debt += positionAssets.mulWadDown(secondsDelayed * memPenaltyRate);
      }

      unchecked {
        ++i;
      }
      if ((1 << i) > packedMaturities) break;
    }
    // calculate floating borrowed debt
    uint256 shares = floatingBorrowShares[account];
    if (shares > 0) debt += previewRefund(shares);
  }

  /// @notice Charges treasury fee to certain amount of earnings.
  /// @dev Mints amount of eTokens on behalf of the treasury address.
  /// @param earnings amount of earnings.
  /// @return earnings minus the fees charged by the treasury.
  function chargeTreasuryFee(uint256 earnings) internal returns (uint256) {
    uint256 memTreasuryFeeRate = treasuryFeeRate;
    if (memTreasuryFeeRate == 0 || earnings == 0) return earnings;

    uint256 fee = earnings.mulWadDown(memTreasuryFeeRate);
    _mint(treasury, previewDeposit(fee));
    floatingAssets += fee;
    return earnings - fee;
  }

  /// @notice Collects all earnings that are charged to borrowers that make use of fixed pool deposits' assets.
  /// @dev Mints amount of eTokens on behalf of the treasury address.
  /// @param earnings amount of earnings.
  function collectFreeLunch(uint256 earnings) internal {
    if (earnings == 0) return;

    if (treasuryFeeRate > 0) {
      _mint(treasury, previewDeposit(earnings));
      floatingAssets += earnings;
    } else {
      earningsAccumulator += earnings;
    }
  }

  /// @notice Calculates the earnings to be distributed from the accumulator given the current timestamp.
  /// @return earnings to be distributed from the accumulator.
  function accumulatedEarnings() internal view returns (uint256 earnings) {
    uint256 elapsed = block.timestamp - lastAccumulatorAccrual;
    if (elapsed == 0) return 0;
    return
      earningsAccumulator.mulDivDown(
        elapsed,
        elapsed + earningsAccumulatorSmoothFactor.mulWadDown(maxFuturePools * FixedLib.INTERVAL)
      );
  }

  /// @notice Accrues the earnings to be distributed from the accumulator given the current timestamp.
  /// @return earnings distributed from the accumulator.
  function accrueAccumulatedEarnings() internal returns (uint256 earnings) {
    earnings = accumulatedEarnings();

    earningsAccumulator -= earnings;
    lastAccumulatorAccrual = uint32(block.timestamp);
    emit AccumulatorAccrual(block.timestamp);
  }

  /// @notice Updates the `floatingAssetsAverage`.
  function updateFloatingAssetsAverage() internal {
    uint256 memFloatingAssets = floatingAssets;
    uint256 memFloatingAssetsAverage = floatingAssetsAverage;
    uint256 dampSpeedFactor = memFloatingAssets < memFloatingAssetsAverage ? dampSpeedDown : dampSpeedUp;
    uint256 averageFactor = uint256(1e18 - (-int256(dampSpeedFactor * (block.timestamp - lastAverageUpdate))).expWad());
    floatingAssetsAverage =
      memFloatingAssetsAverage.mulWadDown(1e18 - averageFactor) +
      averageFactor.mulWadDown(memFloatingAssets);
    lastAverageUpdate = uint32(block.timestamp);
  }

  /// @notice Updates the floating pool borrows' variables.
  function updateFloatingDebt() internal {
    InterestRateModel memIRM = interestRateModel;
    uint256 memFloatingDebt = floatingDebt;
    uint256 memFloatingAssets = floatingAssets;
    uint256 newFloatingUtilization = memFloatingAssets > 0 ? memFloatingDebt.divWadUp(memFloatingAssets) : 0;
    uint256 newDebt = memFloatingDebt.mulWadDown(
      memIRM.floatingBorrowRate(floatingUtilization, newFloatingUtilization).mulDivDown(
        block.timestamp - lastFloatingDebtUpdate,
        365 days
      )
    );

    memFloatingDebt += newDebt;
    floatingAssets += chargeTreasuryFee(newDebt);
    floatingDebt = memFloatingDebt;
    floatingUtilization = newFloatingUtilization;
    lastFloatingDebtUpdate = uint32(block.timestamp);
    emit FloatingDebtUpdate(block.timestamp, newFloatingUtilization);
  }

  /// @notice Calculates the total floating debt, considering elapsed time since last update and current interest rate.
  /// @return actual floating debt plus projected interest.
  function totalFloatingBorrowAssets() public view returns (uint256) {
    InterestRateModel memIRM = interestRateModel;
    uint256 memFloatingAssets = floatingAssets;
    uint256 memFloatingDebt = floatingDebt;
    uint256 newFloatingUtilization = memFloatingAssets > 0 ? memFloatingDebt.divWadUp(memFloatingAssets) : 0;
    uint256 newDebt = memFloatingDebt.mulWadDown(
      memIRM.floatingBorrowRate(floatingUtilization, newFloatingUtilization).mulDivDown(
        block.timestamp - lastFloatingDebtUpdate,
        365 days
      )
    );
    return memFloatingDebt + newDebt;
  }

  /// @notice Calculates the floating pool balance plus earnings to be accrued at current timestamp
  /// from maturities and accumulator.
  /// @return actual floatingAssets plus earnings to be accrued at current timestamp.
  function totalAssets() public view override returns (uint256) {
    unchecked {
      uint256 memMaxFuturePools = maxFuturePools;
      uint256 backupEarnings = 0;

      uint256 latestMaturity = block.timestamp - (block.timestamp % FixedLib.INTERVAL);
      uint256 maxMaturity = latestMaturity + memMaxFuturePools * FixedLib.INTERVAL;

      for (uint256 maturity = latestMaturity; maturity <= maxMaturity; maturity += FixedLib.INTERVAL) {
        FixedLib.Pool storage pool = fixedPools[maturity];
        uint256 lastAccrual = pool.lastAccrual;

        if (maturity > lastAccrual) {
          backupEarnings += pool.unassignedEarnings.mulDivDown(block.timestamp - lastAccrual, maturity - lastAccrual);
        }
      }

      return
        floatingAssets +
        backupEarnings +
        accumulatedEarnings() +
        (totalFloatingBorrowAssets() - floatingDebt).mulWadDown(1e18 - treasuryFeeRate);
    }
  }

  /// @notice Simulates the effects of a borrow at the current time, given current contract conditions.
  /// @param assets amount of assets to borrow.
  /// @return amount of shares that will be asigned to the user after the borrow.
  function previewBorrow(uint256 assets) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? assets : assets.mulDivUp(supply, totalFloatingBorrowAssets());
  }

  /// @notice Simulates the effects of a repay at the current time, given current contract conditions.
  /// @param assets amount of assets to repay.
  /// @return amount of shares that will be subtracted from the user after the repay.
  function previewRepay(uint256 assets) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? assets : assets.mulDivDown(supply, totalFloatingBorrowAssets());
  }

  /// @notice Simulates the effects of a refund at the current time, given current contract conditions.
  /// @param shares amount of shares to subtract from user's accountability.
  /// @return amount of assets that will be repaid.
  function previewRefund(uint256 shares) public view returns (uint256) {
    uint256 supply = totalFloatingBorrowShares; // Saves an extra SLOAD if totalFloatingBorrowShares is non-zero.

    return supply == 0 ? shares : shares.mulDivUp(totalFloatingBorrowAssets(), supply);
  }

  /// @notice Checks msg.sender's allowance over account's assets.
  /// @param account account in which the allowance will be checked.
  /// @param assets assets from account that msg.sender wants to operate on.
  function checkAllowance(address account, uint256 assets) internal {
    if (msg.sender != account) {
      uint256 allowed = allowance[account][msg.sender]; // saves gas for limited approvals.

      if (allowed != type(uint256).max) allowance[account][msg.sender] = allowed - previewWithdraw(assets);
    }
  }

  /// @notice Emits MarketUpdate event.
  /// @dev Internal function to avoid code duplication.
  function emitMarketUpdate() internal {
    emit MarketUpdate(
      block.timestamp,
      totalSupply,
      floatingAssets,
      totalFloatingBorrowShares,
      floatingDebt,
      earningsAccumulator
    );
  }

  /// @notice Emits FixedEarningsUpdate event.
  /// @dev Internal function to avoid code duplication.
  function emitFixedEarningsUpdate(uint256 maturity) internal {
    emit FixedEarningsUpdate(block.timestamp, maturity, fixedPools[maturity].unassignedEarnings);
  }

  /// @notice Sets the rate charged to the mp depositors that the sp suppliers will retain for initially providing
  /// liquidity.
  /// @dev Value can only be set between 20% and 0%.
  /// @param backupFeeRate_ percentage amount represented with 1e18 decimals.
  function setBackupFeeRate(uint256 backupFeeRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    backupFeeRate = backupFeeRate_;
    emit BackupFeeRateSet(backupFeeRate_);
  }

  /// @notice Sets the damp speed used to update the floatingAssetsAverage.
  /// @dev Values can only be set between 0 and 100%.
  /// @param up damp speed up, represented with 18 decimals.
  /// @param down damp speed down, represented with 18 decimals.
  function setDampSpeed(uint256 up, uint256 down) public onlyRole(DEFAULT_ADMIN_ROLE) {
    dampSpeedUp = up;
    dampSpeedDown = down;
    emit DampSpeedSet(up, down);
  }

  /// @notice Sets the factor used when smoothly accruing earnings to the floating pool.
  /// @dev Value cannot be higher than 4. If set at 0, then all remaining accumulated earnings are
  /// distributed in following operation to the floating pool.
  /// @param earningsAccumulatorSmoothFactor_ represented with 18 decimals.
  function setEarningsAccumulatorSmoothFactor(uint128 earningsAccumulatorSmoothFactor_)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    earningsAccumulatorSmoothFactor = earningsAccumulatorSmoothFactor_;
    emit EarningsAccumulatorSmoothFactorSet(earningsAccumulatorSmoothFactor_);
  }

  /// @notice Sets the interest rate model to be used to calculate rates.
  /// @param interestRateModel_ new interest rate model.
  function setInterestRateModel(InterestRateModel interestRateModel_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    interestRateModel = interestRateModel_;
    emit InterestRateModelSet(interestRateModel_);
  }

  /// @notice Sets the protocol's max future pools for borrowing and lending.
  /// @dev Value can not be 0 or higher than 224. If value is decreased, VALID maturities will become NOT_READY.
  /// @param futurePools number of pools to be active at the same time.
  function setMaxFuturePools(uint8 futurePools) public onlyRole(DEFAULT_ADMIN_ROLE) {
    maxFuturePools = futurePools;
    emit MaxFuturePoolsSet(futurePools);
  }

  /// @notice Sets the penalty rate per second.
  /// @dev Value can only be set approximately between 5% and 1% daily.
  /// @param penaltyRate_ percentage represented with 18 decimals.
  function setPenaltyRate(uint256 penaltyRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    penaltyRate = penaltyRate_;
    emit PenaltyRateSet(penaltyRate_);
  }

  /// @notice Sets the percentage that represents the liquidity reserves that can't be borrowed.
  /// @dev Value can only be set between 20% and 0%.
  /// @param reserveFactor_ parameter represented with 18 decimals.
  function setReserveFactor(uint128 reserveFactor_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    reserveFactor = reserveFactor_;
    emit ReserveFactorSet(reserveFactor_);
  }

  /// @notice Sets the treasury variables.
  /// @param treasury_ address of the treasury that will receive the minted eTokens.
  /// @param treasuryFeeRate_ represented with 1e18 decimals.
  function setTreasury(address treasury_, uint256 treasuryFeeRate_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    treasury = treasury_;
    treasuryFeeRate = treasuryFeeRate_;
    emit TreasurySet(treasury_, treasuryFeeRate_);
  }

  /// @notice Sets the pause state to true in case of emergency, triggered by an authorized account.
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /// @notice Sets the pause state to false when threat is gone, triggered by an authorized account.
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /// @notice Event emitted when an account borrows amount of assets from a floating pool.
  /// @param caller address which borrowed the asset.
  /// @param receiver address that received the borrowed assets.
  /// @param borrower address which will be repaying the borrowed assets.
  /// @param assets amount of assets that were borrowed.
  /// @param shares amount of borrow shares assigned to the account.
  event Borrow(
    address indexed caller,
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 shares
  );

  /// @notice Emitted when an account repays amount of assets to a floating pool.
  /// @param caller address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount of assets that was repaid.
  /// @param shares amount of borrow shares that were subtracted from the account's accountability.
  event Repay(address indexed caller, address indexed borrower, uint256 assets, uint256 shares);

  /// @notice Emitted when an account deposits an amount of an asset to a certain fixed rate pool,
  /// collecting fees at the end of the period.
  /// @param maturity maturity at which the account will be able to collect his deposit + his fee.
  /// @param caller address which deposited the assets.
  /// @param owner address that will be able to withdraw the deposited assets.
  /// @param assets amount of the asset that were deposited.
  /// @param fee is the extra amount that it will be collected at maturity.
  event DepositAtMaturity(
    uint256 indexed maturity,
    address indexed caller,
    address indexed owner,
    uint256 assets,
    uint256 fee
  );

  /// @notice Emitted when an account withdraws from a fixed rate pool.
  /// @param maturity maturity where the account withdraw its deposits.
  /// @param caller address which withdraw the asset.
  /// @param receiver address which will be collecting the assets.
  /// @param owner address which had the assets withdrawn.
  /// @param assets amount of the asset that were withdrawn.
  /// @param assetsDiscounted amount of the asset that were deposited (in case of early withdrawal).
  event WithdrawAtMaturity(
    uint256 indexed maturity,
    address caller,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 assetsDiscounted
  );

  /// @notice Emitted when an account borrows amount of an asset from a certain maturity date.
  /// @param maturity maturity in which the account will have to repay the loan.
  /// @param caller address which borrowed the asset.
  /// @param receiver address that received the borrowed assets.
  /// @param borrower address which will be repaying the borrowed assets.
  /// @param assets amount of the asset that were borrowed.
  /// @param fee extra amount that will need to be paid at maturity.
  event BorrowAtMaturity(
    uint256 indexed maturity,
    address caller,
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 fee
  );

  /// @notice Emitted when an account repays its borrows after maturity.
  /// @param maturity maturity where the account repaid its borrowed amounts.
  /// @param caller address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount that was repaid.
  /// @param positionAssets amount of the debt that was covered in this repayment (penalties could have been repaid).
  event RepayAtMaturity(
    uint256 indexed maturity,
    address indexed caller,
    address indexed borrower,
    uint256 assets,
    uint256 positionAssets
  );

  /// @notice Emitted when an account's position had a liquidation.
  /// @param receiver address which repaid the previously borrowed amount.
  /// @param borrower address which had the original debt.
  /// @param assets amount of the asset that were repaid.
  /// @param lendersAssets incentive paid to lenders.
  /// @param seizeMarket address of the asset that were seized by the liquidator.
  /// @param seizedAssets amount seized of the collateral.
  event Liquidate(
    address indexed receiver,
    address indexed borrower,
    uint256 assets,
    uint256 lendersAssets,
    Market indexed seizeMarket,
    uint256 seizedAssets
  );

  /// @notice Emitted when an account's collateral has been seized.
  /// @param liquidator address which seized this collateral.
  /// @param borrower address which had the original debt.
  /// @param assets amount seized of the collateral.
  event Seize(address indexed liquidator, address indexed borrower, uint256 assets);

  /// @notice Emitted when the backupFeeRate parameter is changed by admin.
  /// @param backupFeeRate rate charged to the fixed pools to be accrued by the floating depositors.
  event BackupFeeRateSet(uint256 backupFeeRate);

  /// @notice Emitted when the damp speeds are changed by admin.
  /// @param dampSpeedUp represented with 1e18 decimals.
  /// @param dampSpeedDown represented with 1e18 decimals.
  event DampSpeedSet(uint256 dampSpeedUp, uint256 dampSpeedDown);

  /// @notice Emitted when the earningsAccumulatorSmoothFactor is changed by admin.
  /// @param earningsAccumulatorSmoothFactor factor represented with 1e18 decimals.
  event EarningsAccumulatorSmoothFactorSet(uint256 earningsAccumulatorSmoothFactor);

  /// @notice Emitted when the interestRateModel is changed by admin.
  /// @param interestRateModel new interest rate model to be used to calculate rates.
  event InterestRateModelSet(InterestRateModel indexed interestRateModel);

  /// @notice Emitted when the maxFuturePools is changed by admin.
  /// @param maxFuturePools represented with 0 decimals.
  event MaxFuturePoolsSet(uint256 maxFuturePools);

  /// @notice Emitted when the penaltyRate is changed by admin.
  /// @param penaltyRate penaltyRate percentage per second represented with 1e18 decimals.
  event PenaltyRateSet(uint256 penaltyRate);

  /// @notice Emitted when the reserveFactor is changed by admin.
  /// @param reserveFactor reserveFactor percentage.
  event ReserveFactorSet(uint256 reserveFactor);

  /// @notice Emitted when the treasury variables are changed by admin.
  /// @param treasury address of the treasury that will receive the minted eTokens.
  /// @param treasuryFeeRate represented with 1e18 decimals.
  event TreasurySet(address indexed treasury, uint256 treasuryFeeRate);

  /// @notice Emitted when market state is updated.
  /// @param timestamp current timestamp.
  /// @param floatingDepositShares total floating supply shares.
  /// @param floatingAssets total floating supply assets.
  /// @param floatingBorrowShares total floating borrow shares.
  /// @param floatingDebt total floating borrow assets.
  /// @param earningsAccumulator earnings accumulator.
  event MarketUpdate(
    uint256 timestamp,
    uint256 floatingDepositShares,
    uint256 floatingAssets,
    uint256 floatingBorrowShares,
    uint256 floatingDebt,
    uint256 earningsAccumulator
  );

  /// @notice Emitted when the earnings of a maturity are updated.
  /// @param timestamp current timestamp.
  /// @param maturity maturity date where the earnings were updated.
  /// @param unassignedEarnings pending unassigned earnings.
  event FixedEarningsUpdate(uint256 timestamp, uint256 indexed maturity, uint256 unassignedEarnings);

  /// @notice Emitted when accumulator distributes earnings.
  /// @param timestamp current timestamp.
  event AccumulatorAccrual(uint256 timestamp);

  /// @notice Emitted when the floating debt is updated.
  /// @param timestamp current timestamp.
  /// @param utilization new floating utilization.
  event FloatingDebtUpdate(uint256 timestamp, uint256 utilization);
}

error AlreadyInitialized();
error Disagreement();
error InsufficientProtocolLiquidity();
error NotAuditor();
error SelfLiquidation();
error ZeroWithdraw();
error ZeroRepay();
