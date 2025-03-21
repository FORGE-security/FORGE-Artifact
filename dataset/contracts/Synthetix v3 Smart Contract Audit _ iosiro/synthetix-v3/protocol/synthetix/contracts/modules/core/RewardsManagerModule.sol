//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/errors/AccessError.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/utils/ERC165Helper.sol";

import "../../storage/Account.sol";
import "../../storage/AccountRBAC.sol";
import "../../storage/Pool.sol";

import "../../interfaces/IRewardsManagerModule.sol";

/**
 * @title Module for connecting rewards distributors to vaults.
 * @dev See IRewardsManagerModule.
 */
contract RewardsManagerModule is IRewardsManagerModule {
    using SetUtil for SetUtil.Bytes32Set;
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using SafeCastU32 for uint32;
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;

    using Vault for Vault.Data;
    using Distribution for Distribution.Data;
    using RewardDistribution for RewardDistribution.Data;

    uint256 private constant _MAX_REWARD_DISTRIBUTIONS = 10;

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function registerRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        if (pool.owner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        // Limit the maximum amount of rewards distributors can be connected to each vault to prevent excessive gas usage on other calls
        if (rewardIds.length() > _MAX_REWARD_DISTRIBUTIONS) {
            revert ParameterError.InvalidParameter("index", "too large");
        }

        if (
            !ERC165Helper.safeSupportsInterface(distributor, type(IRewardDistributor).interfaceId)
        ) {
            revert ParameterError.InvalidParameter("distributor", "invalid interface");
        }

        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        if (rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter("distributor", "is already registered");
        }

        rewardIds.add(rewardId);
        if (distributor == address(0)) {
            revert ParameterError.InvalidParameter("distributor", "must be non-zero");
        }
        pool.vaults[collateralType].rewards[rewardId].distributor = IRewardDistributor(distributor);

        emit RewardsDistributorRegistered(poolId, collateralType, distributor);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function distributeRewards(
        uint128 poolId,
        address collateralType,
        uint256 amount,
        uint64 start,
        uint32 duration
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        // Identify the reward id for the caller, and revert if it is not a registered reward distributor.
        bytes32 rewardId = _getRewardId(poolId, collateralType, msg.sender);
        if (!rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter(
                "poolId-collateralType-distributor",
                "reward is not registered"
            );
        }

        RewardDistribution.Data storage reward = pool.vaults[collateralType].rewards[rewardId];

        reward.rewardPerShareD18 += reward
            .distribute(
                pool.vaults[collateralType].currentEpoch().accountsDebtDistribution,
                amount.toInt(),
                start,
                duration
            )
            .toUint()
            .to128();

        emit RewardsDistributed(poolId, collateralType, msg.sender, amount, start, duration);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function getClaimableRewards(
        uint128 poolId,
        address collateralType,
        uint128 accountId
    ) external override returns (uint256[] memory, address[] memory) {
        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        return vault.updateRewards(accountId);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external view override returns (uint256) {
        return _getRewardRate(poolId, collateralType, distributor);
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override returns (uint256) {
        Account.onlyWithPermission(accountId, AccountRBAC._REWARDS_PERMISSION);

        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        bytes32 rewardId = keccak256(abi.encode(poolId, collateralType, distributor));

        if (!vault.rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter("invalid-params", "reward is not found");
        }

        uint256 reward = vault.updateReward(accountId, rewardId);

        vault.rewards[rewardId].distributor.payout(
            accountId,
            poolId,
            collateralType,
            msg.sender,
            reward
        );
        vault.rewards[rewardId].claimStatus[accountId].pendingSendD18 = 0;

        emit RewardsClaimed(
            accountId,
            poolId,
            collateralType,
            address(vault.rewards[rewardId].distributor),
            reward
        );

        return reward;
    }

    /**
     * @dev Return the amount of rewards being distributed to a vault per second
     */
    function _getRewardRate(
        uint128 poolId,
        address collateralType,
        address distributor
    ) internal view returns (uint256) {
        Vault.Data storage vault = Pool.load(poolId).vaults[collateralType];
        uint256 totalShares = vault.currentEpoch().accountsDebtDistribution.totalSharesD18;
        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        int256 curTime = block.timestamp.toInt();

        // No rewards are currently being distributed if the distributor doesn't exist, they are scheduled to be distributed in the future, or the distribution as already completed
        if (
            address(vault.rewards[rewardId].distributor) == address(0) ||
            vault.rewards[rewardId].start > curTime.toUint() ||
            vault.rewards[rewardId].start + vault.rewards[rewardId].duration <= curTime.toUint()
        ) {
            return 0;
        }

        return
            vault.rewards[rewardId].scheduledValueD18.to256().toUint().divDecimal(
                vault.rewards[rewardId].duration.to256().divDecimal(totalShares)
            );
    }

    /**
     * @dev Generate an ID for a rewards distributor connection by hashing its address with the vault's collateral type address and pool id
     */
    function _getRewardId(
        uint128 poolId,
        address collateralType,
        address distributor
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(poolId, collateralType, distributor));
    }

    /**
     * @inheritdoc IRewardsManagerModule
     */
    function removeRewardsDistributor(
        uint128 poolId,
        address collateralType,
        address distributor
    ) external override {
        Pool.Data storage pool = Pool.load(poolId);
        SetUtil.Bytes32Set storage rewardIds = pool.vaults[collateralType].rewardIds;

        if (pool.owner != msg.sender) {
            revert AccessError.Unauthorized(msg.sender);
        }

        bytes32 rewardId = _getRewardId(poolId, collateralType, distributor);

        if (!rewardIds.contains(rewardId)) {
            revert ParameterError.InvalidParameter("distributor", "is not registered");
        }

        rewardIds.remove(rewardId);

        if (distributor == address(0)) {
            revert ParameterError.InvalidParameter("distributor", "must be non-zero");
        }
        pool.vaults[collateralType].rewards[rewardId].distributor = IRewardDistributor(address(0));

        emit RewardsDistributorRemoved(poolId, collateralType, distributor);
    }
}
