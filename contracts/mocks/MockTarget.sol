// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MockTarget
/// @notice Target contract for testing SessionPermissionVerifier + SessionExecutor.
/// It has a function with a selector we can whitelist, and it mutates state.
contract MockTarget {
    uint256 public number;
    address public lastCaller;

    event Ping(address indexed caller, uint256 value);

    function ping(uint256 value) external returns (uint256) {
        number = value;
        lastCaller = msg.sender;
        emit Ping(msg.sender, value);
        return value + 1;
    }
}