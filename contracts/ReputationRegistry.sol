// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IReputationRegistry.sol";

/// @title ReputationRegistry
/// @notice Tracks reputation scores for agents. Only owner (governance) may set scores.
/// @dev ERC-8004-style building block. Scores can be computed off-chain and written here.
contract ReputationRegistry is Ownable, IReputationRegistry {
  constructor() Ownable(msg.sender) {}
    mapping(address => int256) private _scores;

    function setScore(address agent, int256 newScore) external override onlyOwner {
        require(agent != address(0), "ReputationRegistry: zero agent");
        _scores[agent] = newScore;
        emit ScoreUpdated(agent, newScore);
    }

    function scoreOf(address agent) external view override returns (int256) {
        return _scores[agent];
    }
}
