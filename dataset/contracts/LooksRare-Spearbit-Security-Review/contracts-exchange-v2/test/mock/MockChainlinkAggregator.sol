// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract MockChainlinkAggregator {
    int256 private _answer;

    function setAnswer(int256 answer) external {
        _answer = answer;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 1;
        answer = _answer;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}
