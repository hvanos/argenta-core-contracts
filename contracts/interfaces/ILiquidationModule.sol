// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for LiquidationModule
interface ILiquidationModule {
    /// @notice Liquidates a vault if its health factor is below 1.
    function liquidate(uint256 vaultId) external;

    /// @notice Returns the health factor for a given vault.
    function getHealthFactor(uint256 vaultId) external view returns (uint256);
}