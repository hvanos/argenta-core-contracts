// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IInterestRateModel.sol";

/// @title InterestRateModel
/// @notice Simple interest rate model returning a fixed borrow rate per year.
contract InterestRateModel is IInterestRateModel {
    uint256 public immutable baseRate; // expressed as 18 decimal fixed point (e.g. 5% = 0.05 * 1e18)

    constructor(uint256 _baseRate) {
        baseRate = _baseRate;
    }

    /// @inheritdoc IInterestRateModel
    function getBorrowRate(uint256 /*totalDebt*/, uint256 /*totalCollateralValue*/) external view override returns (uint256) {
        return baseRate;
    }
}