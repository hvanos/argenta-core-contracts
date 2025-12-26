// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IValidationRegistry.sol";

/// @title ValidationRegistry
/// @notice Stores attestations that a job executed by an agent was valid.
/// @dev ERC-8004-style building block. In production, validations could be
///      signatures, proofs, or results from multiple validators.
///      Here we store simple records for demo / indexing.
contract ValidationRegistry is Ownable, IValidationRegistry {
  constructor() Ownable(msg.sender) {}
    struct Validation {
        address agent;
        bytes32 jobHash;
        bool valid;
        address submitter;
        uint256 timestamp;
    }

    uint256 public counter;
    mapping(uint256 => Validation) private _validations;

    /// @notice Submit a validation record for an agent job.
    /// @dev Anyone can submit for demo purposes; you may restrict to "validator role" later.
    function submitValidation(address agent, bytes32 jobHash, bool valid) external override {
        require(agent != address(0), "ValidationRegistry: zero agent");
        require(jobHash != bytes32(0), "ValidationRegistry: zero jobHash");

        _validations[counter] = Validation({
            agent: agent,
            jobHash: jobHash,
            valid: valid,
            submitter: msg.sender,
            timestamp: block.timestamp
        });

        emit ValidationSubmitted(counter, agent, jobHash, valid, msg.sender);
        counter++;
    }

    function getValidation(uint256 id)
        external
        view
        override
        returns (address agent, bytes32 jobHash, bool valid, address submitter, uint256 timestamp)
    {
        Validation storage v = _validations[id];
        return (v.agent, v.jobHash, v.valid, v.submitter, v.timestamp);
    }
}
