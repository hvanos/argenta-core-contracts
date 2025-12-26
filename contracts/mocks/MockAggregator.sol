// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MockAggregator
/// @notice Simple Chainlink aggregator mock used for testing.  It returns a
/// constant price that can be updated by the owner.
contract MockAggregator {
    int256 public answer;
    uint8 public immutable decimals;

    constructor(int256 _answer, uint8 _decimals) {
        answer = _answer;
        decimals = _decimals;
    }

    function setAnswer(int256 _answer) external {
        answer = _answer;
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 _answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, answer, 0, 0, 0);
    }
}