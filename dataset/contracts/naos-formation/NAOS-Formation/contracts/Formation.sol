// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {CDP} from "./libraries/formation/CDP.sol";
import {FixedPointMath} from "./libraries/FixedPointMath.sol";
import {ITransmuter} from "./interfaces/ITransmuter.sol";
import {IMintableERC20} from "./interfaces/IMintableERC20.sol";
import {IChainlink} from "./interfaces/IChainlink.sol";
import {IVaultAdapter} from "./interfaces/IVaultAdapter.sol";
import {Vault} from "./libraries/formation/Vault.sol";

import "hardhat/console.sol";
                                                                                              
contract Formation is  ReentrancyGuard {
  using CDP for CDP.Data;
  using FixedPointMath for FixedPointMath.uq192x64;
  using Vault for Vault.Data;
  using Vault for Vault.List;
  using SafeERC20 for IMintableERC20;
  using SafeMath for uint256;
  using Address for address;

  address public constant ZERO_ADDRESS = address(0);

  /// @dev Resolution for all fixed point numeric parameters which represent percents. The resolution allows for a
  /// granularity of 0.01% increments.
  uint256 public constant PERCENT_RESOLUTION = 10000;

  /// @dev The minimum value that the collateralization limit can be set to by the governance. This is a safety rail
  /// to prevent the collateralization from being set to a value which breaks the system.
  ///
  /// This value is equal to 100%.
  ///
  /// IMPORTANT: This constant is a raw FixedPointMath.uq192x64 value and assumes a resolution of 64 bits. If the
  ///            resolution for the FixedPointMath library changes this constant must change as well.
  uint256 public constant MINIMUM_COLLATERALIZATION_LIMIT = 1000000000000000000;

  /// @dev The maximum value that the collateralization limit can be set to by the governance. This is a safety rail
  /// to prevent the collateralization from being set to a value which breaks the system.
  ///
  /// This value is equal to 400%.
  ///
  /// IMPORTANT: This constant is a raw FixedPointMath.uq192x64 value and assumes a resolution of 64 bits. If the
  ///            resolution for the FixedPointMath library changes this constant must change as well.
  uint256 public constant MAXIMUM_COLLATERALIZATION_LIMIT = 4000000000000000000;

  event GovernanceUpdated(
    address governance
  );

  event PendingGovernanceUpdated(
    address pendingGovernance
  );

  event SentinelUpdated(
    address sentinel
  );

  event TransmuterUpdated(
    address transmuter
  );

  event RewardsUpdated(
    address treasury
  );

  event HarvestFeeUpdated(
    uint256 fee
  );

  event CollateralizationLimitUpdated(
    uint256 limit
  );

  event EmergencyExitUpdated(
    bool status
  );

  event ActiveVaultUpdated(
    IVaultAdapter indexed adapter
  );

  event FundsHarvested(
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event FundsRecalled(
    uint256 indexed vaultId,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event FundsFlushed(
    uint256 amount
  );

  event TokensDeposited(
    address indexed account,
    uint256 amount
  );

  event TokensWithdrawn(
    address indexed account,
    uint256 requestedAmount,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  event TokensRepaid(
    address indexed account,
    uint256 parentAmount,
    uint256 childAmount
  );

  event TokensLiquidated(
    address indexed account,
    uint256 requestedAmount,
    uint256 withdrawnAmount,
    uint256 decreasedValue
  );

  /// @dev The token that this contract is using as the parent asset.
  IMintableERC20 public token;

   /// @dev The token that this contract is using as the child asset.
  IMintableERC20 public xtoken;

  /// @dev The address of the account which currently has administrative capabilities over this contract.
  address public governance;

  /// @dev The address of the pending governance.
  address public pendingGovernance;

  /// @dev The address of the account which can initiate an emergency withdraw of funds in a vault.
  address public sentinel;

  /// @dev The address of the contract which will transmute synthetic tokens back into native tokens.
  address public transmuter;

  /// @dev The address of the contract which will receive fees.
  address public rewards;

  /// @dev The percent of each profitable harvest that will go to the rewards contract.
  uint256 public harvestFee;

  /// @dev The total amount the native token deposited into the system that is owned by external users.
  uint256 public totalDeposited;

  /// @dev when movemetns are bigger than this number flush is activated.
  uint256 public flushActivator;

  /// @dev A flag indicating if the contract has been initialized yet.
  bool public initialized;

  /// @dev A flag indicating if deposits and flushes should be halted and if all parties should be able to recall
  /// from the active vault.
  bool public emergencyExit;

  /// @dev The context shared between the CDPs.
  CDP.Context private _ctx;

  /// @dev A mapping of all of the user CDPs. If a user wishes to have multiple CDPs they will have to either
  /// create a new address or set up a proxy contract that interfaces with this contract.
  mapping(address => CDP.Data) private _cdps;

  /// @dev A list of all of the vaults. The last element of the list is the vault that is currently being used for
  /// deposits and withdraws. Vaults before the last element are considered inactive and are expected to be cleared.
  Vault.List private _vaults;

  /// @dev The address of the link oracle.
  address public _linkGasOracle;

  /// @dev The minimum returned amount needed to be on peg according to the oracle.
  uint256 public pegMinimum;
  
  constructor(
    IMintableERC20 _token,
    IMintableERC20 _xtoken,
    address _governance,
    address _sentinel
  )
    public
    /*ERC20(
      string(abi.encodePacked("Formation ", _token.name())),
      string(abi.encodePacked("al", _token.symbol()))
    )*/
  {
    require(_governance != ZERO_ADDRESS, "Formation: governance address cannot be 0x0.");
    require(_sentinel != ZERO_ADDRESS, "Formation: sentinel address cannot be 0x0.");

    token = _token;
    xtoken = _xtoken;
    governance = _governance;
    sentinel = _sentinel;
    flushActivator = 100000 ether;// change for non 18 digit tokens

    //_setupDecimals(_token.decimals());
    uint256 COLL_LIMIT = MINIMUM_COLLATERALIZATION_LIMIT.mul(2);
    _ctx.collateralizationLimit = FixedPointMath.uq192x64(COLL_LIMIT);
    _ctx.accumulatedYieldWeight = FixedPointMath.uq192x64(0);
  }

  /// @dev Sets the pending governance.
  ///
  /// This function reverts if the new pending governance is the zero address or the caller is not the current
  /// governance. This is to prevent the contract governance being set to the zero address which would deadlock
  /// privileged contract functionality.
  ///
  /// @param _pendingGovernance the new pending governance.
  function setPendingGovernance(address _pendingGovernance) external onlyGov {
    require(_pendingGovernance != ZERO_ADDRESS, "Formation: governance address cannot be 0x0.");

    pendingGovernance = _pendingGovernance;

    emit PendingGovernanceUpdated(_pendingGovernance);
  }

  /// @dev Accepts the role as governance.
  ///
  /// This function reverts if the caller is not the new pending governance.
  function acceptGovernance() external  {
    require(msg.sender == pendingGovernance,"sender is not pendingGovernance");
    address _pendingGovernance = pendingGovernance;
    governance = _pendingGovernance;

    emit GovernanceUpdated(_pendingGovernance);
  }

  function setSentinel(address _sentinel) external onlyGov {

    require(_sentinel != ZERO_ADDRESS, "Formation: sentinel address cannot be 0x0.");

    sentinel = _sentinel;

    emit SentinelUpdated(_sentinel);
  }

  /// @dev Sets the transmuter.
  ///
  /// This function reverts if the new transmuter is the zero address or the caller is not the current governance.
  ///
  /// @param _transmuter the new transmuter.
  function setTransmuter(address _transmuter) external onlyGov {

    // Check that the transmuter address is not the zero address. Setting the transmuter to the zero address would break
    // transfers to the address because of `safeTransfer` checks.
    require(_transmuter != ZERO_ADDRESS, "Formation: transmuter address cannot be 0x0.");

    transmuter = _transmuter;

    emit TransmuterUpdated(_transmuter);
  }
  /// @dev Sets the flushActivator.
  ///
  /// @param _flushActivator the new flushActivator.
  function setFlushActivator(uint256 _flushActivator) external onlyGov {
    flushActivator = _flushActivator;

  }

  /// @dev Sets the rewards contract.
  ///
  /// This function reverts if the new rewards contract is the zero address or the caller is not the current governance.
  ///
  /// @param _rewards the new rewards contract.
  function setRewards(address _rewards) external onlyGov {

    // Check that the rewards address is not the zero address. Setting the rewards to the zero address would break
    // transfers to the address because of `safeTransfer` checks.
    require(_rewards != ZERO_ADDRESS, "Formation: rewards address cannot be 0x0.");

    rewards = _rewards;

    emit RewardsUpdated(_rewards);
  }

  /// @dev Sets the harvest fee.
  ///
  /// This function reverts if the caller is not the current governance.
  ///
  /// @param _harvestFee the new harvest fee.
  function setHarvestFee(uint256 _harvestFee) external onlyGov {

    // Check that the harvest fee is within the acceptable range. Setting the harvest fee greater than 100% could
    // potentially break internal logic when calculating the harvest fee.
    require(_harvestFee <= PERCENT_RESOLUTION, "Formation: harvest fee above maximum.");

    harvestFee = _harvestFee;

    emit HarvestFeeUpdated(_harvestFee);
  }

  /// @dev Sets the collateralization limit.
  ///
  /// This function reverts if the caller is not the current governance or if the collateralization limit is outside
  /// of the accepted bounds.
  ///
  /// @param _limit the new collateralization limit.
  function setCollateralizationLimit(uint256 _limit) external onlyGov {

    require(_limit >= MINIMUM_COLLATERALIZATION_LIMIT, "Formation: collateralization limit below minimum.");
    require(_limit <= MAXIMUM_COLLATERALIZATION_LIMIT, "Formation: collateralization limit above maximum.");

    _ctx.collateralizationLimit = FixedPointMath.uq192x64(_limit);

    emit CollateralizationLimitUpdated(_limit);
  }
  /// @dev Set oracle.
  function setOracleAddress(address Oracle, uint256 peg) external onlyGov {
    _linkGasOracle = Oracle;
    pegMinimum = peg;
  }
  /// @dev Sets if the contract should enter emergency exit mode.
  ///
  /// @param _emergencyExit if the contract should enter emergency exit mode.
  function setEmergencyExit(bool _emergencyExit) external {
    require(msg.sender == governance || msg.sender == sentinel, "");

    emergencyExit = _emergencyExit;

    emit EmergencyExitUpdated(_emergencyExit);
  }

  /// @dev Gets the collateralization limit.
  ///
  /// The collateralization limit is the minimum ratio of collateral to debt that is allowed by the system.
  ///
  /// @return the collateralization limit.
  function collateralizationLimit() external view returns (FixedPointMath.uq192x64 memory) {
    return _ctx.collateralizationLimit;
  }

  /// @dev Initializes the contract.
  ///
  /// This function checks that the transmuter and rewards have been set and sets up the active vault.
  ///
  /// @param _adapter the vault adapter of the active vault.
  function initialize(IVaultAdapter _adapter) external onlyGov {

    require(!initialized, "Formation: already initialized");

    require(transmuter != ZERO_ADDRESS, "Formation: cannot initialize transmuter address to 0x0");
    require(rewards != ZERO_ADDRESS, "Formation: cannot initialize rewards address to 0x0");

    _updateActiveVault(_adapter);

    initialized = true;
  }

  /// @dev Migrates the system to a new vault.
  ///
  /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
  /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
  ///
  /// @param _adapter the adapter for the vault the system will migrate to.
  function migrate(IVaultAdapter _adapter) external expectInitialized onlyGov {

    _updateActiveVault(_adapter);
  }

  /// @dev Harvests yield from a vault.
  ///
  /// @param _vaultId the identifier of the vault to harvest from.
  ///
  /// @return the amount of funds that were harvested from the vault.
  function harvest(uint256 _vaultId) external expectInitialized returns (uint256, uint256) {

    Vault.Data storage _vault = _vaults.get(_vaultId);

    (uint256 _harvestedAmount, uint256 _decreasedValue) = _vault.harvest(address(this));

    if (_harvestedAmount > 0) {
      uint256 _feeAmount = _harvestedAmount.mul(harvestFee).div(PERCENT_RESOLUTION);
      uint256 _distributeAmount = _harvestedAmount.sub(_feeAmount);

      FixedPointMath.uq192x64 memory _weight = FixedPointMath.fromU256(_distributeAmount).div(totalDeposited);
      _ctx.accumulatedYieldWeight = _ctx.accumulatedYieldWeight.add(_weight);

      if (_feeAmount > 0) {
        token.safeTransfer(rewards, _feeAmount);
      }

      if (_distributeAmount > 0) {
        _distributeToTransmuter(_distributeAmount);
        
        // token.safeTransfer(transmuter, _distributeAmount); previous version call
      }
    }

    emit FundsHarvested(_harvestedAmount, _decreasedValue);

    return (_harvestedAmount, _decreasedValue);
  }

  /// @dev Recalls an amount of deposited funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function recall(uint256 _vaultId, uint256 _amount) external nonReentrant expectInitialized returns (uint256, uint256) {

    return _recallFunds(_vaultId, _amount);
  }

  /// @dev Recalls all the deposited funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function recallAll(uint256 _vaultId) external nonReentrant expectInitialized returns (uint256, uint256) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _recallFunds(_vaultId, _vault.totalDeposited);
  }

  /// @dev Flushes buffered tokens to the active vault.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @return the amount of tokens flushed to the active vault.
  function flush() external nonReentrant expectInitialized returns (uint256) {

    // Prevent flushing to the active vault when an emergency exit is enabled to prevent potential loss of funds if
    // the active vault is poisoned for any reason.
    require(!emergencyExit, "emergency pause enabled");

    return flushActiveVault();
  }

  /// @dev Internal function to flush buffered tokens to the active vault.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @return the amount of tokens flushed to the active vault.
  function flushActiveVault() internal returns (uint256) {

    Vault.Data storage _activeVault = _vaults.last();
    uint256 _depositedAmount = _activeVault.depositAll();

    emit FundsFlushed(_depositedAmount);

    return _depositedAmount;
  }

  /// @dev Deposits collateral into a CDP.
  ///
  /// This function reverts if an emergency exit is active. This is in place to prevent the potential loss of
  /// additional funds.
  ///
  /// @param _amount the amount of collateral to deposit.
  function deposit(uint256 _amount) external nonReentrant noContractAllowed expectInitialized {

    require(!emergencyExit, "emergency pause enabled");
    
    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    token.safeTransferFrom(msg.sender, address(this), _amount);
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
    totalDeposited = totalDeposited.add(_amount);

    _cdp.totalDeposited = _cdp.totalDeposited.add(_amount);
    _cdp.lastDeposit = block.number;

    emit TokensDeposited(msg.sender, _amount);
  }

  /// @dev Attempts to withdraw part of a CDP's collateral.
  ///
  /// This function reverts if a deposit into the CDP was made in the same block. This is to prevent flash loan attacks
  /// on other internal or external systems.
  ///
  /// @param _amount the amount of collateral to withdraw.
  function withdraw(uint256 _amount) external nonReentrant noContractAllowed expectInitialized returns (uint256, uint256) {

    CDP.Data storage _cdp = _cdps[msg.sender];
    require(block.number > _cdp.lastDeposit, "");

    _cdp.update(_ctx);

    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(msg.sender, _amount);

    _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "Exceeds withdrawable amount");
    _cdp.checkHealth(_ctx, "Action blocked: unhealthy collateralization ratio");
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
    emit TokensWithdrawn(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Repays debt with the native and or synthetic token.
  ///
  /// An approval is required to transfer native tokens to the transmuter.
  function repay(uint256 _parentAmount, uint256 _childAmount) external nonReentrant noContractAllowed onLinkCheck expectInitialized {

    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    if (_parentAmount > 0) {
      token.safeTransferFrom(msg.sender, address(this), _parentAmount);
      _distributeToTransmuter(_parentAmount);
    }

    if (_childAmount > 0) {
      xtoken.burnFrom(msg.sender, _childAmount);
      //lower debt cause burn
      xtoken.lowerHasMinted(_childAmount);
    }

    uint256 _totalAmount = _parentAmount.add(_childAmount);
    _cdp.totalDebt = _cdp.totalDebt.sub(_totalAmount, "");

    emit TokensRepaid(msg.sender, _parentAmount, _childAmount);
  }

  /// @dev Attempts to liquidate part of a CDP's collateral to pay back its debt.
  ///
  /// @param _amount the amount of collateral to attempt to liquidate.
  function liquidate(uint256 _amount) external nonReentrant noContractAllowed onLinkCheck expectInitialized returns (uint256, uint256) {
    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);
    
    // don't attempt to liquidate more than is possible
    if(_amount > _cdp.totalDebt){
      _amount = _cdp.totalDebt;
    }
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _withdrawFundsTo(address(this), _amount);
    //changed to new transmuter compatibillity 
    _distributeToTransmuter(_withdrawnAmount);

    _cdp.totalDeposited = _cdp.totalDeposited.sub(_decreasedValue, "");
    _cdp.totalDebt = _cdp.totalDebt.sub(_withdrawnAmount, "");
    emit TokensLiquidated(msg.sender, _amount, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Mints synthetic tokens by either claiming credit or increasing the debt.
  ///
  /// Claiming credit will take priority over increasing the debt.
  ///
  /// This function reverts if the debt is increased and the CDP health check fails.
  ///
  /// @param _amount the amount of formation tokens to borrow.
  function mint(uint256 _amount) external nonReentrant noContractAllowed onLinkCheck expectInitialized {

    CDP.Data storage _cdp = _cdps[msg.sender];
    _cdp.update(_ctx);

    uint256 _totalCredit = _cdp.totalCredit;

    if (_totalCredit < _amount) {
      uint256 _remainingAmount = _amount.sub(_totalCredit);
      _cdp.totalDebt = _cdp.totalDebt.add(_remainingAmount);
      _cdp.totalCredit = 0;

      _cdp.checkHealth(_ctx, "Formation: Loan-to-value ratio breached");
    } else {
      _cdp.totalCredit = _totalCredit.sub(_amount);
    }

    xtoken.mint(msg.sender, _amount);
    if(_amount >= flushActivator) {
      flushActiveVault();
    }
  }

  /// @dev Gets the number of vaults in the vault list.
  ///
  /// @return the vault count.
  function vaultCount() external view returns (uint256) {
    return _vaults.length();
  }

  /// @dev Get the adapter of a vault.
  ///
  /// @param _vaultId the identifier of the vault.
  ///
  /// @return the vault adapter.
  function getVaultAdapter(uint256 _vaultId) external view returns (IVaultAdapter) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _vault.adapter;
  }

  /// @dev Get the total amount of the parent asset that has been deposited into a vault.
  ///
  /// @param _vaultId the identifier of the vault.
  ///
  /// @return the total amount of deposited tokens.
  function getVaultTotalDeposited(uint256 _vaultId) external view returns (uint256) {
    Vault.Data storage _vault = _vaults.get(_vaultId);
    return _vault.totalDeposited;
  }

  /// @dev Get the total amount of collateral deposited into a CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the deposited amount of tokens.
  function getCdpTotalDeposited(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.totalDeposited;
  }

  /// @dev Get the total amount of formation tokens borrowed from a CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the borrowed amount of tokens.
  function getCdpTotalDebt(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.getUpdatedTotalDebt(_ctx);
  }

  /// @dev Get the total amount of credit that a CDP has.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the amount of credit.
  function getCdpTotalCredit(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.getUpdatedTotalCredit(_ctx);
  }

  /// @dev Gets the last recorded block of when a user made a deposit into their CDP.
  ///
  /// @param _account the user account of the CDP to query.
  ///
  /// @return the block number of the last deposit.
  function getCdpLastDeposit(address _account) external view returns (uint256) {
    CDP.Data storage _cdp = _cdps[_account];
    return _cdp.lastDeposit;
  }
  /// @dev sends tokens to the transmuter
  ///
  /// benefit of great nation of transmuter
  function _distributeToTransmuter(uint256 amount) internal {
        token.approve(transmuter,amount);
        ITransmuter(transmuter).distribute(address(this),amount);
        // lower debt cause of 'burn'
        xtoken.lowerHasMinted(amount);
  } 
  /// @dev Checks that parent token is on peg.
  ///
  /// This is used over a modifier limit of pegged interactions.
  modifier onLinkCheck() {
    if(pegMinimum > 0 ){
      uint256 oracleAnswer = uint256(IChainlink(_linkGasOracle).latestAnswer());
      require(oracleAnswer > pegMinimum, "off peg limitation");
    }
    _;
  }
  /// @dev Checks that caller is not a eoa.
  ///
  /// This is used to prevent contracts from interacting.
  modifier noContractAllowed() {
    require(!address(msg.sender).isContract() && msg.sender == tx.origin, "Sorry we do not accept contract!");
    _;
  }
  /// @dev Checks that the contract is in an initialized state.
  ///
  /// This is used over a modifier to reduce the size of the contract
  modifier expectInitialized() {
    require(initialized, "Formation: not initialized.");
    _;
  }

  /// @dev Checks that the current message sender or caller is a specific address.
  ///
  /// @param _expectedCaller the expected caller.
  function _expectCaller(address _expectedCaller) internal {
    require(msg.sender == _expectedCaller, "");
  }

  /// @dev Checks that the current message sender or caller is the governance address.
  ///
  ///
  modifier onlyGov() {
    require(msg.sender == governance, "Formation: only governance.");
    _;
  }
  /// @dev Updates the active vault.
  ///
  /// This function reverts if the vault adapter is the zero address, if the token that the vault adapter accepts
  /// is not the token that this contract defines as the parent asset, or if the contract has not yet been initialized.
  ///
  /// @param _adapter the adapter for the new active vault.
  function _updateActiveVault(IVaultAdapter _adapter) internal {
    require(_adapter != IVaultAdapter(ZERO_ADDRESS), "Formation: active vault address cannot be 0x0.");
    require(_adapter.token() == token, "Formation: token mismatch.");

    _vaults.push(Vault.Data({
      adapter: _adapter,
      totalDeposited: 0
    }));

    emit ActiveVaultUpdated(_adapter);
  }

  /// @dev Recalls an amount of funds from a vault to this contract.
  ///
  /// @param _vaultId the identifier of the recall funds from.
  /// @param _amount  the amount of funds to recall from the vault.
  ///
  /// @return the amount of funds that were recalled from the vault to this contract and the decreased vault value.
  function _recallFunds(uint256 _vaultId, uint256 _amount) internal returns (uint256, uint256) {
    require(emergencyExit || msg.sender == governance || _vaultId != _vaults.lastIndex(), "Formation: not an emergency, not governance, and user does not have permission to recall funds from active vault");

    Vault.Data storage _vault = _vaults.get(_vaultId);
    (uint256 _withdrawnAmount, uint256 _decreasedValue) = _vault.withdraw(address(this), _amount);

    emit FundsRecalled(_vaultId, _withdrawnAmount, _decreasedValue);

    return (_withdrawnAmount, _decreasedValue);
  }

  /// @dev Attempts to withdraw funds from the active vault to the recipient.
  ///
  /// Funds will be first withdrawn from this contracts balance and then from the active vault. This function
  /// is different from `recallFunds` in that it reduces the total amount of deposited tokens by the decreased
  /// value of the vault.
  ///
  /// @param _recipient the account to withdraw the funds to.
  /// @param _amount    the amount of funds to withdraw.
  function _withdrawFundsTo(address _recipient, uint256 _amount) internal returns (uint256, uint256) {
    // Pull the funds from the buffer.
    uint256 _bufferedAmount = Math.min(_amount, token.balanceOf(address(this)));

    if (_recipient != address(this)) {
      token.safeTransfer(_recipient, _bufferedAmount);
    }

    uint256 _totalWithdrawn = _bufferedAmount;
    uint256 _totalDecreasedValue = _bufferedAmount;

    uint256 _remainingAmount = _amount.sub(_bufferedAmount);

    // Pull the remaining funds from the active vault.
    if (_remainingAmount > 0) {
      Vault.Data storage _activeVault = _vaults.last();
      (uint256 _withdrawAmount, uint256 _decreasedValue) = _activeVault.withdraw(
        _recipient,
        _remainingAmount
      );

      _totalWithdrawn = _totalWithdrawn.add(_withdrawAmount);
      _totalDecreasedValue = _totalDecreasedValue.add(_decreasedValue);
    }

    totalDeposited = totalDeposited.sub(_totalDecreasedValue);

    return (_totalWithdrawn, _totalDecreasedValue);
  }
}