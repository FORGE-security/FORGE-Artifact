pragma solidity ^0.4.24;

import '../../contracts/VotingToManageEmissionFunds.sol';


contract VotingToManageEmissionFundsMock is VotingToManageEmissionFunds {
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
}