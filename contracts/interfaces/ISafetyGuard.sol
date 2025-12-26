// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ISafetyGuard
/// @notice Interface for Argenta SafetyGuard.
interface ISafetyGuard {
    function checkAddCollateral(uint256 currentCollateralValue, uint256 addValue) external view returns (bool);
    function checkBorrow(
        uint256 currentVaultDebt,
        uint256 addDebt,
        uint256 totalSystemDebt
    ) external view returns (bool);
}
