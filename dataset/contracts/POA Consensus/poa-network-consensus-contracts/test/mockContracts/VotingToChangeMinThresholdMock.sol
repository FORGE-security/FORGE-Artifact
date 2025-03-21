pragma solidity ^0.4.24;

import '../../contracts/VotingToChangeMinThreshold.sol';


contract VotingToChangeMinThresholdMock is VotingToChangeMinThreshold {
    uint256 public time;

    function setTime(uint256 _newTime) public {
        time = _newTime;
    }

    function getTime() public view returns(uint256) {
        if (time == 0) {
            return now;
        } else {
          return time;
        }
    }

    function setMinPossibleThreshold(uint256 _minPossibleThreshold) public {
        uintStorage[MIN_POSSIBLE_THRESHOLD] = _minPossibleThreshold;
    }
}