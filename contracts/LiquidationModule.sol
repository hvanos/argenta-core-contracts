// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILiquidationModule.sol";
import "./interfaces/IArgentaVault.sol";

/// @title LiquidationModule
/// @notice Handles liquidation of under‑collateralised vaults.  When a vault’s
/// health factor falls below 1, anyone may call `liquidate` to seize the
/// collateral.  This is a simplified implementation: in a real protocol you
/// would auction collateral, pay a liquidation bonus, and handle partial
/// liquidations.
contract LiquidationModule is Ownable, ILiquidationModule {
    IArgentaVault public vault;

    event Liquidated(uint256 indexed vaultId, address indexed liquidator);
    
    constructor() Ownable(msg.sender) {}

    /// @notice Sets the address of the ArgentaVault.
    function setVault(IArgentaVault _vault) external onlyOwner {
        vault = _vault;
    }

    /// @inheritdoc ILiquidationModule
    function liquidate(uint256 vaultId) external override {
        require(address(vault) != address(0), "LiquidationModule: vault not set");
        uint256 health = vault.getHealthFactor(vaultId);
        require(health < 1e18, "LiquidationModule: vault healthy");
        // call vault to perform liquidation.  We use a dedicated function on the vault
        vault.closeVault(vaultId);
        emit Liquidated(vaultId, msg.sender);
    }

    /// @inheritdoc ILiquidationModule
    function getHealthFactor(uint256 vaultId) external view override returns (uint256) {
        return vault.getHealthFactor(vaultId);
    }
}