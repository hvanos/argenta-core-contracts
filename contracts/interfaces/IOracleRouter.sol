// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for OracleRouter
interface IOracleRouter {
    /// @notice Returns the USD price for a given asset, scaled to 18 decimals.
    function getPrice(address asset) external view returns (uint256);
}