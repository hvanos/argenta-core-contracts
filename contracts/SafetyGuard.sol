// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISafetyGuard.sol";

/// @title SafetyGuard
/// @notice Provides global and per‑vault safety limits for the protocol.  The
/// ArgentaVault queries this contract to ensure deposits and borrows remain
/// within configured bounds.  Governance (owner) can update limits.
contract SafetyGuard is Ownable, ISafetyGuard {
    uint256 public maxTotalDebt;         // maximum stablecoin debt allowed system‑wide
    uint256 public maxDebtPerVault;      // maximum debt per individual vault
    uint256 public maxCollateralPerVault; // maximum collateral value per vault (USD, 18 decimals)

    event LimitsUpdated(uint256 maxTotalDebt, uint256 maxDebtPerVault, uint256 maxCollateralPerVault);
    
    constructor(uint256 _maxTotalDebt, uint256 _maxDebtPerVault, uint256 _maxCollateralPerVault) Ownable(msg.sender) {
        maxTotalDebt = _maxTotalDebt;
        maxDebtPerVault = _maxDebtPerVault;
        maxCollateralPerVault = _maxCollateralPerVault;
    }

    /// @notice Updates all limits.  Only owner.
    function setLimits(uint256 _maxTotalDebt, uint256 _maxDebtPerVault, uint256 _maxCollateralPerVault) external onlyOwner {
        maxTotalDebt = _maxTotalDebt;
        maxDebtPerVault = _maxDebtPerVault;
        maxCollateralPerVault = _maxCollateralPerVault;
        emit LimitsUpdated(_maxTotalDebt, _maxDebtPerVault, _maxCollateralPerVault);
    }

    /// @notice Checks whether adding collateral keeps the vault below its maximum.
    /// @dev `currentCollateralValue` and `addValue` should be expressed in USD (18 decimals).
    function checkAddCollateral(uint256 currentCollateralValue, uint256 addValue) external view returns (bool) {
        return currentCollateralValue + addValue <= maxCollateralPerVault;
    }

    /// @notice Checks whether minting additional debt is within per‑vault and total limits.
    /// @param currentVaultDebt The current debt of the vault.
    /// @param addDebt The additional debt requested.
    /// @param totalSystemDebt The current total debt in the system.
    /// @return allowed True if the mint is allowed.
    function checkBorrow(uint256 currentVaultDebt, uint256 addDebt, uint256 totalSystemDebt) external view returns (bool allowed) {
        if (currentVaultDebt + addDebt > maxDebtPerVault) return false;
        if (totalSystemDebt + addDebt > maxTotalDebt) return false;
        return true;
    }
}