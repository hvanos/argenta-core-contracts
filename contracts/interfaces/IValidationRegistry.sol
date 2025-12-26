// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IValidationRegistry
/// @notice Minimal interface for validation attestations for agent jobs (ERC-8004-style building block).
interface IValidationRegistry {
    event ValidationSubmitted(uint256 indexed id, address indexed agent, bytes32 indexed jobHash, bool valid, address submitter);

    function submitValidation(address agent, bytes32 jobHash, bool valid) external;
    function getValidation(uint256 id)
        external
        view
        returns (address agent, bytes32 jobHash, bool valid, address submitter, uint256 timestamp);
}
