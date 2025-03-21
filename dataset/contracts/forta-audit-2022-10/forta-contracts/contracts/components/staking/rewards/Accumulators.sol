// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-protocol/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

uint256 constant EPOCH_LENGTH = 1 weeks;
// Timestamp 0 was in Thursday, 1 January 1970 0:00:00 GMT. We start epochs on Monday 0:00:00 GMT
uint256 constant TIMESTAMP_OFFSET = 4 days;

library Accumulators {
    struct EpochCheckpoint {
        uint32 timestamp;
        uint224 rate;
        uint256 value;
    }

    struct Accumulator {
        EpochCheckpoint[] checkpoints;
    }

    function getValue(Accumulator storage acc) internal view returns (uint256) {
        EpochCheckpoint memory origin = latest(acc);
        return origin.value + origin.rate * (block.timestamp - origin.timestamp);
    }

    function getValueAtEpoch(Accumulator storage acc, uint256 epoch) internal view returns (uint256) {
        EpochCheckpoint memory origin = getAtEpoch(acc, epoch);
        return origin.value + origin.rate * (getEpochEndTimestamp(epoch) - origin.timestamp);
    }

    function addRate(Accumulator storage acc, uint256 rate) internal {
        setRate(acc, latest(acc).rate + rate);
    }

    function subRate(Accumulator storage acc, uint256 rate) internal {
        setRate(acc, latest(acc).rate - rate);
    }

    function setRate(Accumulator storage acc, uint256 rate) internal {
        EpochCheckpoint memory ckpt = EpochCheckpoint({ timestamp: SafeCast.toUint32(block.timestamp), rate: SafeCast.toUint224(rate), value: getValue(acc) });
        uint256 length = acc.checkpoints.length;
        if (length > 0 && isCurrentEpoch(acc.checkpoints[length - 1].timestamp)) {
            acc.checkpoints[length - 1] = ckpt;
        } else {
            acc.checkpoints.push(ckpt);
        }
    }

    function latest(Accumulator storage acc) internal view returns (EpochCheckpoint memory) {
        uint256 length = acc.checkpoints.length;
        if (length == 0) {
            return zeroEpoch();
        } else {
            return acc.checkpoints[length - 1];
        }
    }

    function checkPointLength(Accumulator storage acc) internal view returns (uint256) {
        return acc.checkpoints.length;
    }

    /**
     * @dev Returns the most recent checkpoint during a given epoch. If a checkpoint is not available at that
     * epoch, the closest one before it is returned, or a zero epoch checkpoint otherwise.
     */
    function getAtEpoch(Accumulator storage acc, uint256 epochNumber) internal view returns (EpochCheckpoint memory) {
        require(epochNumber < getCurrentEpochNumber(), "Checkpoints: epoch not yet finished");

        uint256 epochEnd = getEpochEndTimestamp(epochNumber);

        uint256 high = acc.checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (acc.checkpoints[mid].timestamp > epochEnd) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? zeroEpoch() : acc.checkpoints[high - 1];
    }

    function zeroEpoch() private pure returns (EpochCheckpoint memory) {
        return EpochCheckpoint({ timestamp: 0, rate: 0, value: 0 });
    }

    function getCurrentEpochNumber() internal view returns (uint32) {
        return getEpochNumber(block.timestamp);
    }

    function getEpochNumber(uint256 timestamp) internal pure returns (uint32) {
        return SafeCast.toUint32((timestamp - TIMESTAMP_OFFSET) / EPOCH_LENGTH);
    }

    function getEpochEndTimestamp(uint256 epochNumber) internal pure returns (uint256) {
        return ((epochNumber + 1) * EPOCH_LENGTH) + TIMESTAMP_OFFSET;
    }

    function getCurrentEpochTimestamp() internal view returns (uint256) {
        return ((block.timestamp / EPOCH_LENGTH) * EPOCH_LENGTH) + TIMESTAMP_OFFSET;
    }

    function isCurrentEpoch(uint256 timestamp) internal view returns (bool) {
        uint256 currentEpochStart = getCurrentEpochTimestamp();
        return timestamp > currentEpochStart;
    }
}
