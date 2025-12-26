// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IAgentRegistry
/// @notice Minimal interface for an on-chain agent registry (ERC-8004-style building block).
interface IAgentRegistry {
    event AgentRegistered(address indexed agent, string metadataURI);
    event AgentUpdated(address indexed agent, string metadataURI, bool active);

    function register(string calldata metadataURI) external;
    function setActive(address agent, bool active) external;

    function getAgent(address agent)
        external
        view
        returns (string memory metadataURI, bool active, uint256 registeredAt);
}
