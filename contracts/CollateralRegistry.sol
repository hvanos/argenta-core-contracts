// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICollateralRegistry.sol";

/// @title CollateralRegistry
/// @notice Stores a list of supported collateral tokens and their risk parameters.
contract CollateralRegistry is Ownable, ICollateralRegistry {
    mapping(address => CollateralData) private _collaterals;
    
    constructor() Ownable(msg.sender) {}

    /// @notice Adds or updates collateral parameters.
    /// @param token The address of the collateral token.
    /// @param mcr The minimum collateralisation ratio (basis points, e.g. 15000 = 150%).
    /// @param liquidationThreshold The threshold at which liquidation may occur.
    /// @param maxCap Maximum total collateral the system will accept for this token.
    /// @param enabled Whether the collateral is active.
    function setCollateral(
        address token,
        uint256 mcr,
        uint256 liquidationThreshold,
        uint256 maxCap,
        bool enabled
    ) external onlyOwner {
        require(token != address(0), "CollateralRegistry: zero address");
        require(mcr > 0 && liquidationThreshold > 0, "CollateralRegistry: invalid params");
        _collaterals[token] = CollateralData({
            mcr: mcr,
            liquidationThreshold: liquidationThreshold,
            maxCap: maxCap,
            enabled: enabled
        });
    }

    /// @inheritdoc ICollateralRegistry
    function isSupported(address token) external view override returns (bool) {
        return _collaterals[token].mcr != 0 && _collaterals[token].enabled;
    }

    /// @inheritdoc ICollateralRegistry
    function getParams(address token) external view override returns (CollateralData memory) {
        return _collaterals[token];
    }
}