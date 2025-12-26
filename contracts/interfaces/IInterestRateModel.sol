// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Interface for InterestRateModel
interface IInterestRateModel {
    /// @notice Returns the current borrow rate, expressed as a per‑year rate with 18 decimals.
    /// @param totalDebt The total system debt.
    /// @param totalCollateralValue The total collateral value (in USD) in the system.
    function getBorrowRate(uint256 totalDebt, uint256 totalCollateralValue) external view returns (uint256);
}