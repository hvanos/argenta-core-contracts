// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OracleRouter.sol";

/// @title ETHUSDOracle
/// @notice Convenience wrapper around OracleRouter to fetch ETH/USD price.
contract ETHUSDOracle {
    OracleRouter public immutable router;

    constructor(OracleRouter _router) {
        router = _router;
    }

    /// @notice Returns the price of 1 ETH in USD (18 decimals).
    function getPrice() external view returns (uint256) {
        // Using the zero address to represent native ETH in the router
        return router.getPrice(address(0));
    }
}