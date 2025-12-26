// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for ArgentaVault
/// @notice Defines the external functions available on the ArgentaVault contract.
interface IArgentaVault {
    /// @notice Emitted when a new vault is opened.

    /// @notice Opens a new vault for the caller and returns its ID.
    function openVault() external returns (uint256 vaultId);

    /// @notice Deposits collateral into a vault.
    /// @param vaultId The ID of the vault.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to deposit.
    function addCollateral(uint256 vaultId, address token, uint256 amount) external payable;

    /// @notice Withdraws collateral from a vault.
    /// @param vaultId The ID of the vault.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to withdraw.
    function removeCollateral(uint256 vaultId, address token, uint256 amount) external;

    /// @notice Mints stablecoin against the collateral in a vault.
    /// @param vaultId The ID of the vault.
    /// @param amount The amount of stablecoin to mint.
    function borrow(uint256 vaultId, uint256 amount) external;

    /// @notice Repays debt and burns stablecoin.
    /// @param vaultId The ID of the vault.
    /// @param amount The amount of stablecoin to repay.
    function repay(uint256 vaultId, uint256 amount) external;

    /// @notice Closes a vault, repaying all debt and returning collateral.
    /// @param vaultId The ID of the vault.
    function closeVault(uint256 vaultId) external;

    /// @notice Returns the current collateral value and debt of a vault.
    function getPosition(uint256 vaultId) external view returns (uint256 collateralValue, uint256 debt);

    /// @notice Returns the health factor (collateral ratio divided by MCR).
    function getHealthFactor(uint256 vaultId) external view returns (uint256);
}