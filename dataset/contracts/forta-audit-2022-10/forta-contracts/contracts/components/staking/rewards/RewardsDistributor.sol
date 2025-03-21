// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-protocol/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.9;

import "./Accumulators.sol";
import "./IRewardsDistributor.sol";
import "../stake_subjects/StakeSubjectGateway.sol";
import "../FortaStakingUtils.sol";
import "../../../tools/Distributions.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Timers.sol";

uint256 constant MAX_BPS = 10000;

contract RewardsDistributor is BaseComponentUpgradeable, SubjectTypeValidator, IRewardsDistributor {
    using Timers for Timers.Timestamp;
    using Accumulators for Accumulators.Accumulator;
    using Distributions for Distributions.Balances;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable rewardsToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    StakeSubjectGateway private immutable _subjectGateway;

    string public constant version = "0.1.0";

    struct DelegatedAccRewards {
        Accumulators.Accumulator delegated;
        Accumulators.Accumulator delegators;
        Accumulators.Accumulator delegatorsTotal;
        mapping(address => Accumulators.Accumulator) delegatorsPortions;
    }

    uint256 public totalRewardsDistributed;
    // delegator share id => DelegatedAccRewards
    mapping(uint256 => DelegatedAccRewards) private _rewardsAccumulators;
    // share => epoch => amount
    mapping(uint256 => mapping(uint256 => uint256)) private _rewardsPerEpoch;
    // share => epoch => address => claimed
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private _claimedRewardsPerEpoch;

    struct DelegationFee {
        uint16 feeBps;
        uint240 sinceEpoch;
    }
    // share => DelegationFee [prev, curr]
    mapping(uint256 => DelegationFee[2]) public delegationFees;

    uint256 public delegationParamsEpochDelay;
    uint256 public defaultFeeBps;

    event DidAccumulateRate(uint8 indexed subjectType, uint256 indexed subject, address indexed staker, uint256 stakeAmount, uint256 sharesAmount);
    event DidReduceRate(uint8 indexed subjectType, uint256 indexed subject, address indexed staker, uint256 stakeAmount, uint256 sharesAmount);
    event Rewarded(uint8 indexed subjectType, uint256 indexed subject, uint256 amount, uint256 epochNumber);
    event ClaimedRewards(uint8 indexed subjectType, uint256 indexed subject, address indexed to, uint256 epochNumber, uint256 value);
    event DidTransferRewardShares(uint256 indexed sharesId, uint8 subjectType, address indexed from, address indexed to, uint256 sharesAmount);
    event SetDelegationFee(uint8 indexed subjectType, uint256 indexed subject, uint256 epochNumber, uint256 feeBps);
    event SetDelegationParams(uint256 epochDelay, uint256 defaultFeeBps);
    event TokensSwept(address indexed token, address to, uint256 amount);

    error RewardingNonRegisteredSubject(uint8 subjectType, uint256 subject);
    error AlreadyClaimed();
    error SetDelegationFeeNotReady();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _forwarder,
        address _rewardsToken,
        address __subjectGateway
    ) initializer ForwardedContext(_forwarder) {
        if (_rewardsToken == address(0)) revert ZeroAddress("_rewardsToken");
        if (__subjectGateway == address(0)) revert ZeroAddress("__subjectGateway");
        rewardsToken = IERC20(_rewardsToken);
        _subjectGateway = StakeSubjectGateway(__subjectGateway);
    }

    function initialize(address _manager, uint256 _delegationParamsEpochDelay, uint256 _defaultFeeBps) public initializer {
        __BaseComponentUpgradeable_init(_manager);

        if (_delegationParamsEpochDelay == 0) revert ZeroAmount("_delegationParamsEpochDelay");
        delegationParamsEpochDelay = _delegationParamsEpochDelay;
        // defaultFeeBps could be 0;
        defaultFeeBps = _defaultFeeBps;
    }

    /********** Epoch number getters **********/
    function didAllocate(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeAmount,
        uint256 sharesAmount,
        address staker
    ) external onlyRole(ALLOCATOR_CONTRACT_ROLE) {
        bool delegated = getSubjectTypeAgency(subjectType) == SubjectStakeAgency.DELEGATED;
        if (delegated) {
            uint8 delegatorType = getDelegatorSubjectType(subjectType);
            uint256 shareId = FortaStakingUtils.subjectToActive(delegatorType, subject);
            DelegatedAccRewards storage s = _rewardsAccumulators[shareId];
            s.delegated.addRate(stakeAmount);
        } else {
            uint256 shareId = FortaStakingUtils.subjectToActive(subjectType, subject);
            DelegatedAccRewards storage s = _rewardsAccumulators[shareId];
            s.delegators.addRate(stakeAmount);
            if (staker != address(0)) {
                s.delegatorsTotal.addRate(sharesAmount);
                s.delegatorsPortions[staker].addRate(sharesAmount);
            }
        }
        emit DidAccumulateRate(subjectType, subject, staker, stakeAmount, sharesAmount);
    }

    function didUnallocate(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeAmount,
        uint256 sharesAmount,
        address staker
    ) external onlyRole(ALLOCATOR_CONTRACT_ROLE) {
        bool delegated = getSubjectTypeAgency(subjectType) == SubjectStakeAgency.DELEGATED;
        if (delegated) {
            uint8 delegatorType = getDelegatorSubjectType(subjectType);
            uint256 shareId = FortaStakingUtils.subjectToActive(delegatorType, subject);
            DelegatedAccRewards storage s = _rewardsAccumulators[shareId];
            s.delegated.subRate(stakeAmount);
        } else {
            uint256 shareId = FortaStakingUtils.subjectToActive(subjectType, subject);
            DelegatedAccRewards storage s = _rewardsAccumulators[shareId];
            s.delegators.subRate(stakeAmount);
            if (staker != address(0)) {
                s.delegatorsTotal.subRate(sharesAmount);
                s.delegatorsPortions[staker].subRate(sharesAmount);
            }
        }
        emit DidReduceRate(subjectType, subject, staker, stakeAmount, sharesAmount);
    }

    function didTransferShares(
        uint256 sharesId,
        uint8 subjectType,
        address from,
        address to,
        uint256 sharesAmount
    ) external onlyRole(ALLOCATOR_CONTRACT_ROLE) onlyAgencyType(subjectType, SubjectStakeAgency.DELEGATOR) {
        DelegatedAccRewards storage s = _rewardsAccumulators[sharesId];
        if (s.delegatorsPortions[from].latest().rate > 0) {
            s.delegatorsPortions[from].subRate(sharesAmount);
        }
        s.delegatorsPortions[to].addRate(sharesAmount);
        emit DidTransferRewardShares(sharesId, subjectType, from, to, sharesAmount);
    }

    /********** Reward management **********/
    function reward(
        uint8 subjectType,
        uint256 subjectId,
        uint256 amount,
        uint256 epochNumber
    ) external onlyRole(REWARDER_ROLE) {
        if (subjectType != NODE_RUNNER_SUBJECT) revert InvalidSubjectType(subjectType);
        if (!_subjectGateway.isRegistered(subjectType, subjectId)) revert RewardingNonRegisteredSubject(subjectType, subjectId);
        uint256 shareId = FortaStakingUtils.subjectToActive(getDelegatorSubjectType(subjectType), subjectId);
        _rewardsPerEpoch[shareId][epochNumber] = amount;
        totalRewardsDistributed += amount;
        emit Rewarded(subjectType, subjectId, amount, epochNumber);
    }

    function availableReward(
        uint8 subjectType,
        uint256 subjectId,
        uint256 epochNumber,
        address staker
    ) public view returns (uint256) {
        (uint256 shareId, bool isDelegator) = _getShareId(subjectType, subjectId);
        if (_claimedRewardsPerEpoch[shareId][epochNumber][staker]) {
            return 0;
        }
        return _availableReward(shareId, isDelegator, epochNumber, staker);
    }

    function _availableReward(
        uint256 shareId,
        bool delegator,
        uint256 epochNumber,
        address staker
    ) internal view returns (uint256) {
        DelegatedAccRewards storage s = _rewardsAccumulators[shareId];

        uint256 N = s.delegated.getValueAtEpoch(epochNumber);
        uint256 D = s.delegators.getValueAtEpoch(epochNumber);
        uint256 T = N + D;

        if (T == 0) {
            return 0;
        }

        uint256 feeBps = _getDelegationFee(shareId, epochNumber);

        uint256 R = _rewardsPerEpoch[shareId][epochNumber];
        uint256 RD = Math.mulDiv(R, D, T);
        uint256 fee = (RD * feeBps) / MAX_BPS; // mulDiv not necessary - feeBps is small

        if (delegator) {
            uint256 r = RD - fee;
            uint256 d = s.delegatorsPortions[staker].getValueAtEpoch(epochNumber);
            uint256 DT = s.delegatorsTotal.getValueAtEpoch(epochNumber);
            return Math.mulDiv(r, d, DT);
        } else {
            uint256 RN = Math.mulDiv(R, N, T);
            return RN + fee;
        }
    }

    function claimRewards(
        uint8 subjectType,
        uint256 subjectId,
        uint256[] calldata epochNumbers
    ) external {
        (uint256 shareId, bool isDelegator) = _getShareId(subjectType, subjectId);
        if (!isDelegator) {
            if (_subjectGateway.ownerOf(subjectType, subjectId) != _msgSender()) revert SenderNotOwner(_msgSender(), subjectId);
        }
        for (uint256 i = 0; i < epochNumbers.length; i++) {
            if (_claimedRewardsPerEpoch[shareId][epochNumbers[i]][_msgSender()]) revert AlreadyClaimed();
            _claimedRewardsPerEpoch[shareId][epochNumbers[i]][_msgSender()] = true;
            uint256 epochRewards = _availableReward(shareId, isDelegator, epochNumbers[i], _msgSender());
            SafeERC20.safeTransfer(rewardsToken, _msgSender(), epochRewards);
            emit ClaimedRewards(subjectType, subjectId, _msgSender(), epochNumbers[i], epochRewards);
        }
    }


    /********** Delegation parameters **********/

    
    function setDelegationParams(uint256 _delegationParamsEpochDelay, uint256 _defaultFeeBps) external onlyRole(STAKING_ADMIN_ROLE) {
        if (_delegationParamsEpochDelay == 0) revert ZeroAmount("_delegationParamsEpochDelay");
        delegationParamsEpochDelay = delegationParamsEpochDelay;
        // defaultFeeBps could be 0;
        defaultFeeBps = _defaultFeeBps;
        emit SetDelegationParams(delegationParamsEpochDelay, defaultFeeBps);
    }

    /**
     * Sets delegation fee for a Node Runner (required to own the NodeRunnerRegistry NFT).
     * Change in fees will start having an effect in the beginning of the next reward epoch.
     * After the first time setting the parameter, it cannot be set again until delegationParamsEpochDelay epochs pass.
     * @param subjectType a DELEGATED subject type.
     * @param subjectId the DELEGATED subject id.
     */
    function setDelegationFeeBps(uint8 subjectType, uint256 subjectId, uint16 feeBps) external onlyAgencyType(subjectType, SubjectStakeAgency.DELEGATED)  {
        if (feeBps > MAX_BPS) revert AmountTooLarge(feeBps, MAX_BPS);
        (uint256 shareId, bool isDelegator) = _getShareId(subjectType, subjectId);
        if (!isDelegator && _subjectGateway.ownerOf(subjectType, subjectId) != _msgSender()) revert SenderNotOwner(_msgSender(), subjectId);

        DelegationFee[2] storage fees = delegationFees[shareId];

        if (fees[1].sinceEpoch != 0) {
            if (Accumulators.getCurrentEpochNumber() < fees[1].sinceEpoch + delegationParamsEpochDelay) revert SetDelegationFeeNotReady();
        }
        if (fees[1].sinceEpoch != 0) {
            fees[0] = fees[1];
        }
        fees[1] = DelegationFee({ feeBps: feeBps, sinceEpoch: Accumulators.getCurrentEpochNumber() + 1 });
        emit SetDelegationFee(subjectType, subjectId, fees[1].sinceEpoch, feeBps);
    }


    /// Returns current delegation fee for an epoch or defaultFeeBps if not set
    function getDelegationFee(uint8 subjectType, uint256 subjectId, uint256 epochNumber) public view returns(uint256) {
        (uint256 shareId, ) = _getShareId(subjectType, subjectId);
        return _getDelegationFee(shareId, epochNumber);
    }

    function _getDelegationFee(uint256 shareId, uint256 epochNumber) private view returns(uint256) {
        DelegationFee[2] storage fees = delegationFees[shareId];
        return _getFee(fees, 1, epochNumber);
    }

    function _getFee(DelegationFee[2] storage fees, uint256 index, uint256 epochNumber) private view returns(uint256) {
        if (fees[index].feeBps == 0) {
            // No fees set yet
            return defaultFeeBps;
        }
        if (epochNumber >= fees[index].sinceEpoch) {
            return fees[index].feeBps;
        } else if (index > 0) {
            return _getFee(fees, index - 1, epochNumber);
        } else {
            return defaultFeeBps;
        }
    }

    function _getShareId(uint8 subjectType, uint256 subjectId) private pure returns (uint256 shareId, bool isDelegator) {
        isDelegator = getSubjectTypeAgency(subjectType) == SubjectStakeAgency.DELEGATOR;
        shareId = isDelegator
            ? FortaStakingUtils.subjectToActive(subjectType, subjectId)
            : FortaStakingUtils.subjectToActive(getDelegatorSubjectType(subjectType), subjectId);
        return (shareId, isDelegator);
    }

    /**
     * @notice Sweep all token that might be mistakenly sent to the contract. This covers both unrelated tokens and staked
     * tokens that would be sent through a direct transfer. Restricted to SWEEPER_ROLE.
     * If tokens are the same as staked tokens, only the extra tokens (no rewards) will be transferred.
     * @dev WARNING: thoroughly review the token to sweep.
     * @param token address of the token to be swept.
     * @param recipient destination address of the swept tokens
     * @return amount of tokens swept. For unrelated tokens is RewardDistributor's balance, for stakedToken its
     * the balance minus total rewards distributed;
     */
    function sweep(IERC20 token, address recipient) external onlyRole(SWEEPER_ROLE) returns (uint256) {
        uint256 amount = token.balanceOf(address(this));

        if (token == rewardsToken) {
            amount -= totalRewardsDistributed;
        }

        SafeERC20.safeTransfer(token, recipient, amount);
        emit TokensSwept(address(token), recipient, amount);
        return amount;
    }

    /********** Epoch number getters **********/

    function getCurrentEpochNumber() external view returns (uint32) {
        return Accumulators.getCurrentEpochNumber();
    }

    function getEpochNumber(uint256 timestamp) external pure returns (uint32) {
        return Accumulators.getEpochNumber(timestamp);
    }

    function getEpochEndTimestamp(uint256 epochNumber) external pure returns (uint256) {
        return Accumulators.getEpochEndTimestamp(epochNumber);
    }

    function getCurrentEpochTimestamp() external view returns (uint256) {
        return Accumulators.getCurrentEpochTimestamp();
    }  
}
