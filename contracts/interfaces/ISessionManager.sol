// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for Session Manager / Permission Verifier
/// @notice Checks whether a given call is permitted under a user‑defined session.
interface ISessionManager {
    /// @notice Verifies whether an encoded call can be executed under a particular permission context.
    /// @param user The owner of the session.
    /// @param target The contract being called.
    /// @param data The calldata for the call.
    /// @return allowed True if the call is allowed.
    function verify(address user, address target, bytes calldata data) external view returns (bool allowed);
}