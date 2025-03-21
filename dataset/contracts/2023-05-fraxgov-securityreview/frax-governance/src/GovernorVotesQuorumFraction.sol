// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0-rc.0) (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import "./GovernorVotes.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token and a quorum expressed as a
 * fraction of the total supply.
 *
 * _Available since v4.3._
 */
abstract contract GovernorVotesQuorumFraction is GovernorVotes {
    using SafeCast for *;
    using Checkpoints for Checkpoints.Trace224;

    /// @custom:oz-retyped-from Checkpoints.History
    Checkpoints.Trace224 private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    constructor(
        address veFxsVotingDelegation,
        string memory _name,
        uint256 quorumNumeratorValue,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    )
        GovernorVotes(
            IVotes(veFxsVotingDelegation),
            _name,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold
        )
    {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific timepoint. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 timepoint) public view virtual returns (uint256) {
        // If history is empty, fallback to old storage
        uint256 length = _quorumNumeratorHistory._checkpoints.length;

        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint224 memory latest = _quorumNumeratorHistory._checkpoints[length - 1];
        if (latest._key <= timepoint) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.upperLookupRecent(SafeCast.toUint32(timepoint));
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a timepoint, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 timepoint) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(timepoint) * quorumNumerator(timepoint)) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(SafeCast.toUint32(clock()), SafeCast.toUint224(newQuorumNumerator));

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
}
