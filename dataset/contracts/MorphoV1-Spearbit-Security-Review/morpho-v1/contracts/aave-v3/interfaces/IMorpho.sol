// SPDX-License-Identifier: GNU AGPLv3
pragma solidity >=0.5.0;

import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import "./aave/IPool.sol";
import "./IEntryPositionsManager.sol";
import "./IExitPositionsManager.sol";
import "./IInterestRatesManager.sol";
import "./IIncentivesVault.sol";
import "./IRewardsManager.sol";

import "../libraries/Types.sol";

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function NO_REFERRAL_CODE() external view returns (uint8);
    function VARIABLE_INTEREST_MODE() external view returns (uint8);
    function MAX_BASIS_POINTS() external view returns (uint16);
    function DEFAULT_LIQUIDATION_CLOSE_FACTOR() external view returns (uint256);
    function HEALTH_FACTOR_LIQUIDATION_THRESHOLD() external view returns (uint256);
    function MAX_NB_OF_MARKETS() external view returns (uint256);
    function MAX_LIQUIDATION_CLOSE_FACTOR() external view returns (uint256);
    function BORROWING_MASK() external view returns(bytes32);
    function ONE() external view returns(bytes32);
    function isClaimRewardsPaused() external view returns (bool);
    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function deltas(address) external view returns (Types.Delta memory);
    function market(address) external view returns (Types.Market memory);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function poolIndexes(address) external view returns (Types.PoolIndexes memory);
    function interestRatesManager() external view returns (IInterestRatesManager);
    function rewardsManager() external view returns (IRewardsManager);
    function entryPositionsManager() external view returns (IEntryPositionsManager);
    function exitPositionsManager() external view returns (IExitPositionsManager);
    function rewardsController() external view returns (IRewardsController);
    function addressesProvider() external view returns (IPoolAddressesProvider);
    function incentivesVault() external view returns (IIncentivesVault);
    function pool() external view returns (IPool);
    function treasuryVault() external view returns (address);
    function borrowMask(address) external view returns (bytes32);
    function userMarkets(address) external view returns (bytes32);

    /// UTILS ///

    function updateIndexes(address _poolToken) external;

    /// GETTERS ///

    function getMarketsCreated() external view returns (address[] memory marketsCreated_);
    function getHead(address _poolToken, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolToken, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setIncentivesVault(address _newIncentivesVault) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setExitPositionsManager(IExitPositionsManager _exitPositionsManager) external;
    function setEntryPositionsManager(IEntryPositionsManager _entryPositionsManager) external;
    function setInterestRatesManager(IInterestRatesManager _interestRatesManager) external;
    function setTreasuryVault(address _newTreasuryVaultAddress) external;
    function setIsP2PDisabled(address _poolToken, bool _isP2PDisabled) external;
    function setReserveFactor(address _poolToken, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolToken, uint16 _p2pIndexCursor) external;
    function setIsPausedForAllMarkets(bool _isPaused) external;
    function setIsClaimRewardsPaused(bool _isPaused) external;
    function setIsSupplyPaused(address _poolToken, bool _isPaused) external;
    function setIsBorrowPaused(address _poolToken, bool _isPaused) external;
    function setIsWithdrawPaused(address _poolToken, bool _isPaused) external;
    function setIsRepayPaused(address _poolToken, bool _isPaused) external;
    function setIsLiquidateCollateralPaused(address _poolToken, bool _isPaused) external;
    function setIsLiquidateBorrowPaused(address _poolToken, bool _isPaused) external;
    function claimToTreasury(address[] calldata _poolTokens, uint256[] calldata _amounts) external;
    function createMarket(address _underlyingToken, uint16 _reserveFactor, uint16 _p2pIndexCursor) external;

    /// USERS ///

    function supply(address _poolToken, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolToken, uint256 _amount) external;
    function borrow(address _poolToken, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolToken, uint256 _amount) external;
    function withdraw(address _poolToken, uint256 _amount, address _receiver) external;
    function repay(address _poolToken, uint256 _amount) external;
    function repay(address _poolToken, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowed, address _poolTokenCollateral, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _assets, bool _tradeForMorphoToken) external returns (address[] memory rewardTokens, uint256[] memory claimedAmounts);
}
