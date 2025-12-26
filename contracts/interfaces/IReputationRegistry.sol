// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IReputationRegistry
/// @notice Minimal interface for reputation scores for agents (ERC-8004-style building block).
interface IReputationRegistry {
    event ScoreUpdated(address indexed agent, int256 newScore);

    function setScore(address agent, int256 newScore) external;
    function scoreOf(address agent) external view returns (int256);
}
