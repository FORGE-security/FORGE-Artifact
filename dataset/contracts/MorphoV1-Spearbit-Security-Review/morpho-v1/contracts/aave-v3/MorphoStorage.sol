// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.10;

import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import "./interfaces/aave/IPool.sol";
import "./interfaces/IEntryPositionsManager.sol";
import "./interfaces/IExitPositionsManager.sol";
import "./interfaces/IInterestRatesManager.sol";
import "./interfaces/IIncentivesVault.sol";
import "./interfaces/IRewardsManager.sol";

import "@morpho-dao/morpho-data-structures/HeapOrdering.sol";
import "./libraries/Types.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title MorphoStorage.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice All storage variables used in Morpho contracts.
abstract contract MorphoStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// GLOBAL STORAGE ///

    uint8 public constant NO_REFERRAL_CODE = 0;
    uint8 public constant VARIABLE_INTEREST_MODE = 2;
    uint16 public constant MAX_BASIS_POINTS = 10_000; // 100% in basis points.
    uint256 public constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 5_000; // 50% in basis points.
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18; // Health factor below which the positions can be liquidated.
    uint256 public constant MAX_NB_OF_MARKETS = 128;
    uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 10_000; // 100% in basis points.
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18; // Health factor below which the positions can be liquidated, whether or not the price oracle sentinel allows the liquidation.
    bytes32 public constant BORROWING_MASK =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    bytes32 public constant ONE =
        0x0000000000000000000000000000000000000000000000000000000000000001;

    bool public isClaimRewardsPaused; // Whether claiming rewards is paused or not.
    uint256 public maxSortedUsers; // The max number of users to sort in the data structure.
    Types.MaxGasForMatching public defaultMaxGasForMatching; // The default max gas to consume within loops in matching engine functions.

    /// POSITIONS STORAGE ///

    mapping(address => HeapOrdering.HeapArray) internal suppliersInP2P; // For a given market, the suppliers in peer-to-peer.
    mapping(address => HeapOrdering.HeapArray) internal suppliersOnPool; // For a given market, the suppliers on Aave.
    mapping(address => HeapOrdering.HeapArray) internal borrowersInP2P; // For a given market, the borrowers in peer-to-peer.
    mapping(address => HeapOrdering.HeapArray) internal borrowersOnPool; // For a given market, the borrowers on Aave.
    mapping(address => mapping(address => Types.SupplyBalance)) public supplyBalanceInOf; // For a given market, the supply balance of a user. aToken -> user -> balances.
    mapping(address => mapping(address => Types.BorrowBalance)) public borrowBalanceInOf; // For a given market, the borrow balance of a user. aToken -> user -> balances.
    mapping(address => bytes32) public userMarkets; // The markets entered by a user as a bitmask.

    /// MARKETS STORAGE ///

    address[] internal marketsCreated; // Keeps track of the created markets.
    mapping(address => uint256) public p2pSupplyIndex; // Current index from supply peer-to-peer unit to underlying (in ray).
    mapping(address => uint256) public p2pBorrowIndex; // Current index from borrow peer-to-peer unit to underlying (in ray).
    mapping(address => Types.PoolIndexes) public poolIndexes; // Last pool index stored.
    mapping(address => Types.Market) public market; // Market information.
    mapping(address => Types.Delta) public deltas; // Delta parameters for each market.
    mapping(address => bytes32) public borrowMask; // Borrow mask of the given market, shift left to get the supply mask.

    /// CONTRACTS AND ADDRESSES ///

    IPoolAddressesProvider public addressesProvider;
    IRewardsController public rewardsController;
    IPool public pool;

    IEntryPositionsManager public entryPositionsManager;
    IExitPositionsManager public exitPositionsManager;
    IInterestRatesManager public interestRatesManager;
    IIncentivesVault public incentivesVault;
    IRewardsManager public rewardsManager;
    address public treasuryVault;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @dev The contract is automatically marked as initialized when deployed so that nobody can highjack the implementation contract.
    constructor() initializer {}
}
