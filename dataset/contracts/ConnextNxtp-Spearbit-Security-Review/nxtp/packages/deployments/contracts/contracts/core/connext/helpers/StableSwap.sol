// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {SwapUtilsExternal as SwapUtils} from "../libraries/SwapUtilsExternal.sol";

import {OwnerPausableUpgradeable} from "./OwnerPausableUpgradeable.sol";
import {LPToken} from "./LPToken.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract StableSwap is IStableSwap, OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
  using SwapUtils for SwapUtils.Swap;

  // ============ Events ============
  event SwapInitialized(SwapUtils.Swap swap, address caller);

  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Storage ============

  // Struct storing data responsible for automatic market maker functionalities. In order to
  // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
  SwapUtils.Swap public swapStorage;

  // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
  // getTokenIndex function also relies on this mapping to retrieve token index.
  mapping(address => uint8) private tokenIndexes;

  // ============ Initializers ============

  /**
   * @notice Initializes this Swap contract with the given parameters.
   * This will also clone a LPToken contract that represents users'
   * LP positions. The owner of LPToken will be this contract - which means
   * only this contract is allowed to mint/burn tokens.
   *
   * @param _pooledTokens an array of ERC20s this pool will accept
   * @param decimals the decimals to use for each pooled token,
   * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
   * @param lpTokenName the long-form name of the token to be deployed
   * @param lpTokenSymbol the short symbol for the token to be deployed
   * @param _a the amplification coefficient * n * (n - 1). See the
   * StableSwap paper for details
   * @param _fee default swap fee to be initialized with
   * @param _adminFee default adminFee to be initialized with
   * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
   */
  function initialize(
    IERC20[] memory _pooledTokens,
    uint8[] memory decimals,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 _a,
    uint256 _fee,
    uint256 _adminFee,
    address lpTokenTargetAddress
  ) public override initializer {
    __OwnerPausable_init();
    __ReentrancyGuard_init();

    // Check _pooledTokens and precisions parameter
    require(_pooledTokens.length > 1, "_pooledTokens.length <= 1");
    require(_pooledTokens.length <= 32, "_pooledTokens.length > 32");
    require(_pooledTokens.length == decimals.length, "_pooledTokens decimals mismatch");

    uint256[] memory precisionMultipliers = new uint256[](decimals.length);

    for (uint8 i = 0; i < _pooledTokens.length; i++) {
      if (i != 0) {
        // Check if index is already used. Check if 0th element is a duplicate.
        require(
          tokenIndexes[address(_pooledTokens[i])] == 0 && _pooledTokens[0] != _pooledTokens[i],
          "Duplicate tokens"
        );
      }
      require(address(_pooledTokens[i]) != address(0), "The 0 address isn't an ERC-20");
      require(decimals[i] <= SwapUtils.POOL_PRECISION_DECIMALS, "Token decimals exceeds max");
      precisionMultipliers[i] = 10**uint256(SwapUtils.POOL_PRECISION_DECIMALS - decimals[i]);
      tokenIndexes[address(_pooledTokens[i])] = i;
    }

    // Check _a, _fee, _adminFee, _withdrawFee parameters
    require(_a < SwapUtils.MAX_A, "_a exceeds maximum");
    require(_fee < SwapUtils.MAX_SWAP_FEE, "_fee exceeds maximum");
    require(_adminFee < SwapUtils.MAX_ADMIN_FEE, "_adminFee exceeds maximum");

    // Initialize a LPToken contract
    LPToken lpToken = LPToken(Clones.clone(lpTokenTargetAddress));
    require(lpToken.initialize(lpTokenName, lpTokenSymbol), "could not init lpToken clone");

    // Initialize swapStorage struct
    swapStorage.lpToken = lpToken;
    swapStorage.pooledTokens = _pooledTokens;
    swapStorage.tokenPrecisionMultipliers = precisionMultipliers;
    swapStorage.balances = new uint256[](_pooledTokens.length);
    swapStorage.adminFees = new uint256[](_pooledTokens.length);
    swapStorage.initialA = _a * SwapUtils.A_PRECISION;
    swapStorage.futureA = _a * SwapUtils.A_PRECISION;
    // swapStorage.initialATime = 0;
    // swapStorage.futureATime = 0;
    swapStorage.swapFee = _fee;
    swapStorage.adminFee = _adminFee;

    emit SwapInitialized(swapStorage, msg.sender);
  }

  // ============ Modifiers ============

  /**
   * @notice Modifier to check deadline against current timestamp
   * @param deadline latest timestamp to accept this transaction
   */
  modifier deadlineCheck(uint256 deadline) {
    require(block.timestamp <= deadline, "Deadline not met");
    _;
  }

  // ============ View functions ============

  /**
   * @notice Return A, the amplification coefficient * n * (n - 1)
   * @dev See the StableSwap paper for details
   * @return A parameter
   */
  function getA() external view override returns (uint256) {
    return swapStorage.getA();
  }

  /**
   * @notice Return A in its raw precision form
   * @dev See the StableSwap paper for details
   * @return A parameter in its raw precision form
   */
  function getAPrecise() external view returns (uint256) {
    return swapStorage.getAPrecise();
  }

  /**
   * @notice Return address of the pooled token at given index. Reverts if tokenIndex is out of range.
   * @param index the index of the token
   * @return address of the token at given index
   */
  function getToken(uint8 index) public view override returns (IERC20) {
    require(index < swapStorage.pooledTokens.length, "Out of range");
    return swapStorage.pooledTokens[index];
  }

  /**
   * @notice Return the index of the given token address. Reverts if no matching
   * token is found.
   * @param tokenAddress address of the token
   * @return the index of the given token address
   */
  function getTokenIndex(address tokenAddress) public view override returns (uint8) {
    uint8 index = tokenIndexes[tokenAddress];
    require(address(getToken(index)) == tokenAddress, "Token does not exist");
    return index;
  }

  /**
   * @notice Return current balance of the pooled token at given index
   * @param index the index of the token
   * @return current balance of the pooled token at given index with token's native precision
   */
  function getTokenBalance(uint8 index) external view override returns (uint256) {
    require(index < swapStorage.pooledTokens.length, "Index out of range");
    return swapStorage.balances[index];
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice() external view override returns (uint256) {
    return swapStorage.getVirtualPrice();
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell. If the token charges
   * a fee on transfers, use the amount that gets transferred after the fee.
   * @return amount of tokens the user will receive
   */
  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view override returns (uint256) {
    return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dy the amount of tokens the user wants to buy
   * @return amount of tokens the user have to transfer
   */
  function calculateSwapOut(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dy
  ) external view override returns (uint256) {
    return swapStorage.calculateSwapInv(tokenIndexFrom, tokenIndexTo, dy);
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param assetIn the token the user wants to swap from
   * @param assetOut the token the user wants to swap to
   * @param amountIn the amount of tokens the user wants to swap from
   * @return amount of tokens the user will receive
   */
  function calculateSwapFromAddress(
    address assetIn,
    address assetOut,
    uint256 amountIn
  ) external view override returns (uint256) {
    uint8 tokenIndexFrom = getTokenIndex(assetIn);
    uint8 tokenIndexTo = getTokenIndex(assetOut);
    return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, amountIn);
  }

  /**
   * @notice Calculate amount of tokens you receive on swap
   * @param assetIn the token the user wants to swap from
   * @param assetOut the token the user wants to swap to
   * @param amountOut the amount of tokens the user wants to swap to
   * @return amount of tokens the user will receive
   */
  function calculateSwapOutFromAddress(
    address assetIn,
    address assetOut,
    uint256 amountOut
  ) external view override returns (uint256) {
    uint8 tokenIndexFrom = getTokenIndex(assetIn);
    uint8 tokenIndexTo = getTokenIndex(assetOut);
    return swapStorage.calculateSwapInv(tokenIndexFrom, tokenIndexTo, amountOut);
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return token amount the user will receive
   */
  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view override returns (uint256) {
    return swapStorage.calculateTokenAmount(amounts, deposit);
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of LP tokens
   * @param amount the amount of LP tokens that would be burned on withdrawal
   * @return array of token balances that the user will receive
   */
  function calculateRemoveLiquidity(uint256 amount) external view override returns (uint256[] memory) {
    return swapStorage.calculateRemoveLiquidity(amount);
  }

  /**
   * @notice Calculate the amount of underlying token available to withdraw
   * when withdrawing via only single token
   * @param tokenAmount the amount of LP token to burn
   * @param tokenIndex index of which token will be withdrawn
   * @return availableTokenAmount calculated amount of underlying token
   * available to withdraw
   */
  function calculateRemoveLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex)
    external
    view
    override
    returns (uint256 availableTokenAmount)
  {
    return swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
  }

  /**
   * @notice This function reads the accumulated amount of admin fees of the token with given index
   * @param index Index of the pooled token
   * @return admin's token balance in the token's precision
   */
  function getAdminBalance(uint256 index) external view returns (uint256) {
    return swapStorage.getAdminBalance(index);
  }

  // ============ External functions ============

  /**
   * @notice Swap two tokens using this pool
   * @param tokenIndexFrom the token the user wants to swap from
   * @param tokenIndexTo the token the user wants to swap to
   * @param dx the amount of tokens the user wants to swap from
   * @param minDy the min amount the user would like to receive, or revert.
   * @param deadline latest timestamp to accept this transaction
   */
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
  }

  /**
   * @notice Swap two tokens using this pool
   * @param assetIn the token the user wants to swap from
   * @param assetOut the token the user wants to swap to
   * @param amountIn the amount of tokens the user wants to swap from
   * @param minAmountOut the min amount of tokens the user wants to swap to
   */
  function swapExact(
    uint256 amountIn,
    address assetIn,
    address assetOut,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    uint8 tokenIndexFrom = getTokenIndex(assetIn);
    uint8 tokenIndexTo = getTokenIndex(assetOut);
    return swapStorage.swap(tokenIndexFrom, tokenIndexTo, amountIn, minAmountOut);
  }

  /**
   * @notice Swap two tokens using this pool
   * @param assetIn the token the user wants to swap from
   * @param assetOut the token the user wants to swap to
   * @param amountOut the amount of tokens the user wants to swap to
   * @param maxAmountIn the max amount of tokens the user wants to swap from
   */
  function swapExactOut(
    uint256 amountOut,
    address assetIn,
    address assetOut,
    uint256 maxAmountIn,
    uint256 deadline
  ) external payable override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    uint8 tokenIndexFrom = getTokenIndex(assetIn);
    uint8 tokenIndexTo = getTokenIndex(assetOut);
    return swapStorage.swapOut(tokenIndexFrom, tokenIndexTo, amountOut, maxAmountIn);
  }

  /**
   * @notice Add liquidity to the pool with the given amounts of tokens
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP token user minted and received
   */
  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.addLiquidity(amounts, minToMint);
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   *        acceptable for this burn. Useful as a front-running mitigation
   * @param deadline latest timestamp to accept this transaction
   * @return amounts of tokens user received
   */
  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external override nonReentrant deadlineCheck(deadline) returns (uint256[] memory) {
    return swapStorage.removeLiquidity(amount, minAmounts);
  }

  /**
   * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @param tokenAmount the amount of the token you want to receive
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @param deadline latest timestamp to accept this transaction
   * @return amount of chosen token user received
   */
  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.removeLiquidityOneToken(tokenAmount, tokenIndex, minAmount);
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances. Withdraw fee that decays linearly
   * over period of 4 weeks since last deposit will apply.
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @param deadline latest timestamp to accept this transaction
   * @return amount of LP tokens burned
   */
  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external override nonReentrant whenNotPaused deadlineCheck(deadline) returns (uint256) {
    return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
  }

  // ============ Admin functions ============

  /**
   * @notice Withdraw all admin fees to the contract owner
   */
  function withdrawAdminFees() external nonReentrant onlyOwner {
    swapStorage.withdrawAdminFees(owner());
  }

  /**
   * @notice Update the admin fee. Admin fee takes portion of the swap fee.
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(uint256 newAdminFee) external onlyOwner {
    swapStorage.setAdminFee(newAdminFee);
  }

  /**
   * @notice Update the swap fee to be applied on swaps
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(uint256 newSwapFee) external onlyOwner {
    swapStorage.setSwapFee(newSwapFee);
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA and futureTime
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param futureA the new A to ramp towards
   * @param futureTime timestamp when the new A should be reached
   */
  function rampA(uint256 futureA, uint256 futureTime) external onlyOwner {
    swapStorage.rampA(futureA, futureTime);
  }

  /**
   * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
   */
  function stopRampA() external onlyOwner {
    swapStorage.stopRampA();
  }
}
