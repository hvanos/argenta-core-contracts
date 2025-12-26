// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OracleRouter.sol";

/// @title LSTPriceOracle
/// @notice Fetches price of a liquid staking token (LST) using OracleRouter.
contract LSTPriceOracle {
    OracleRouter public immutable router;
    address public immutable token;

    constructor(OracleRouter _router, address _token) {
        router = _router;
        token = _token;
    }

    /// @notice Returns the price of 1 LST in USD (18 decimals).
    function getPrice() external view returns (uint256) {
        return router.getPrice(token);
    }
}