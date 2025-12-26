// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAgentRegistry.sol";

/// @title AgentRegistry
/// @notice Simplistic on-chain registry for agents participating in the protocol.
/// @dev This is an ERC-8004-style building block (identity/discovery). A full
///      ERC-8004 implementation can be layered on top (ERC-721 identity, richer metadata, etc.).
contract AgentRegistry is Ownable, IAgentRegistry {
  constructor() Ownable(msg.sender) {}
    struct AgentInfo {
        string metadataURI;
        bool active;
        uint256 registeredAt;
    }

    mapping(address => AgentInfo) private agents;

    /// @notice Registers the caller as an agent with a metadata URI.
    function register(string calldata metadataURI) external override {
        require(bytes(metadataURI).length != 0, "AgentRegistry: empty metadata");
        AgentInfo storage info = agents[msg.sender];

        // If first time registration, set timestamp.
        if (info.registeredAt == 0) {
            info.registeredAt = block.timestamp;
        }

        info.metadataURI = metadataURI;
        info.active = true;

        emit AgentRegistered(msg.sender, metadataURI);
        emit AgentUpdated(msg.sender, metadataURI, true);
    }

    /// @notice Governance can deactivate/reactivate an agent (e.g., malicious behaviour).
    function setActive(address agent, bool active) external override onlyOwner {
        require(agent != address(0), "AgentRegistry: zero agent");
        AgentInfo storage info = agents[agent];
        require(info.registeredAt != 0, "AgentRegistry: not registered");

        info.active = active;
        emit AgentUpdated(agent, info.metadataURI, active);
    }

    /// @notice Returns agent metadata and status.
    function getAgent(address agent)
        external
        view
        override
        returns (string memory metadataURI, bool active, uint256 registeredAt)
    {
        AgentInfo storage info = agents[agent];
        return (info.metadataURI, info.active, info.registeredAt);
    }
}
