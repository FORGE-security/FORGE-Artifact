// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IRewardManager {
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);
    event SoldRewardTokens(uint256 targetTokenReceived);
    event ExtraRewardAdded(address reward);
    event ExtraRewardRemoved(address reward);
    event ExtraRewardsCurvePoolSet(address extraReward, address curvePool);
    event FeesSet(uint256 feePercentage);
    event FeesEnabled(uint256 feePercentage);
    event EarningsClaimed(
        address indexed claimedBy,
        uint256 cncEarned,
        uint256 crvEarned,
        uint256 cvxEarned
    );

    function accountCheckpoint(address account) external;

    function poolCheckpoint() external returns (bool);

    function addExtraReward(address reward) external returns (bool);

    function addBatchExtraRewards(address[] memory rewards) external;

    function conicPool() external view returns (address);

    function setFeePercentage(uint256 _feePercentage) external;

    function claimableRewards(
        address account
    ) external view returns (uint256 cncRewards, uint256 crvRewards, uint256 cvxRewards);

    function claimEarnings() external returns (uint256, uint256, uint256);

    function claimPoolEarningsAndSellRewardTokens() external;
}
