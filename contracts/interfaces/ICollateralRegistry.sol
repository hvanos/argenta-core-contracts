// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for CollateralRegistry
/// @notice Defines the parameters required for each collateral token.
interface ICollateralRegistry {
    struct CollateralData {
        uint256 mcr; // Minimum collateralisation ratio (e.g. 150% = 15000 basis points)
        uint256 liquidationThreshold; // Ratio at which liquidation can happen
        uint256 maxCap; // Maximum amount of collateral the system will accept
        bool enabled; // Whether the collateral is active
    }

    /// @notice Returns whether a token is supported.
    function isSupported(address token) external view returns (bool);

    /// @notice Returns the risk parameters for a token.
    function getParams(address token) external view returns (CollateralData memory);
}