// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for DebtEngine
interface IDebtEngine {
    /// @notice Mints stablecoin to an address.
    /// @dev Only the vault can call this function.
    function mint(address to, uint256 amount) external;

    /// @notice Burns stablecoin from an address.
    /// @dev Only the vault can call this function.
    function burn(address from, uint256 amount) external;
    
    /// @notice Increases the debt for a vault
    function increaseDebt(uint256 vaultId, uint256 amount) external;
    
    /// @notice Decreases the debt for a vault
    function decreaseDebt(uint256 vaultId, uint256 amount) external;

    /// @notice Returns the current debt associated with a vault.
    function debtOf(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the total outstanding debt in the system.
    function totalDebt() external view returns (uint256);
}