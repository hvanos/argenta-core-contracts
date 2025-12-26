// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Math Utility Library
/// @notice Provides simple math helpers missing from Solidity 0.8.x.
library Math {
    /// @dev Returns the smaller of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Returns the larger of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}