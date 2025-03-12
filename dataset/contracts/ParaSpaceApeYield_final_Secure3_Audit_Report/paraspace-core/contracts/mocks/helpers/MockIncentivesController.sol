// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IRewardController} from "../../interfaces/IRewardController.sol";

contract MockIncentivesController is IRewardController {
    function getAssetData(address)
        external
        pure
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function assets(address)
        external
        pure
        override
        returns (
            uint128,
            uint128,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function setClaimer(address, address) external override {}

    function getClaimer(address) external pure override returns (address) {
        return address(1);
    }

    function configureAssets(address[] calldata, uint256[] calldata)
        external
        override
    {}

    function handleAction(
        address,
        uint256,
        uint256
    ) external override {}

    function getRewardsBalance(address[] calldata, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function claimRewards(
        address[] calldata,
        uint256,
        address
    ) external pure override returns (uint256) {
        return 0;
    }

    function claimRewardsOnBehalf(
        address[] calldata,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        return 0;
    }

    function getRewardsByAsset(address)
        external
        pure
        returns (address[] memory)
    {
        address[] memory rewards;

        return (rewards);
    }

    function getRewardsData(address, address)
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0, 0);
    }

    function getAssetDecimals(address) external pure returns (uint8) {
        return 8;
    }

    function getUserUnclaimedRewards(address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function getUserAssetData(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function REWARD_TOKEN() external pure override returns (address) {
        return address(0);
    }

    function PRECISION() external pure override returns (uint8) {
        return 0;
    }

    function DISTRIBUTION_END() external pure override returns (uint256) {
        return 0;
    }
}
