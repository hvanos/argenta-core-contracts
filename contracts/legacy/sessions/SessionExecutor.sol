// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../interfaces/ISessionManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SessionExecutor
/// @notice Executes arbitrary calls on behalf of users after verifying permissions
/// through a session manager.  This contract demonstrates how a session
/// permission verifier could be integrated.  In production the executor
/// should include gas refund mechanisms and allow for meta‑transactions.
contract SessionExecutor is Ownable, ReentrancyGuard {
    ISessionManager public sessionManager;

    event CallExecuted(address indexed user, address indexed target, bytes data, bytes returnData);

    constructor(ISessionManager _sessionManager) Ownable(msg.sender) {
        sessionManager = _sessionManager;
    }

    /// @notice Updates the session manager contract.  Only owner.
    function setSessionManager(ISessionManager _sessionManager) external onlyOwner {
        sessionManager = _sessionManager;
    }

    /// @notice Executes a call on behalf of a user after verifying permission.
    /// @param user The owner of the session (msg.sender in most cases).
    /// @param target The contract to call.
    /// @param data The calldata for the call.
    function execute(address user, address target, bytes calldata data) external nonReentrant returns (bytes memory) {
        require(sessionManager.verify(user, target, data), "SessionExecutor: permission denied");
        (bool success, bytes memory returnData) = target.call(data);
        require(success, "SessionExecutor: call failed");
        emit CallExecuted(user, target, data, returnData);
        return returnData;
    }
}