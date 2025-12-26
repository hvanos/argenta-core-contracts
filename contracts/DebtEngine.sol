// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDebtEngine.sol";
import "./interfaces/IStablecoin.sol";

/// @title DebtEngine
/// @notice Handles minting and burning of USDa stablecoin and keeps per‑vault debt records.
/// Only the vault contract may call `mint` and `burn` functions.
contract DebtEngine is Ownable, IDebtEngine {
    IStablecoin public immutable stablecoin;
    address public vault;

    // vaultId -> debt amount
    mapping(uint256 => uint256) private _vaultDebt;
    uint256 private _totalDebt;

    constructor(address _stablecoin) Ownable(msg.sender) {
        require(_stablecoin != address(0), "DebtEngine: zero address");
        stablecoin = IStablecoin(_stablecoin);
    }

    /// @notice Sets the vault address allowed to mint/burn.  Only owner can call.
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /// @inheritdoc IDebtEngine
    function mint(address to, uint256 amount) external override {
        require(msg.sender == vault, "DebtEngine: not vault");
        stablecoin.mint(to, amount);
        _totalDebt += amount;
    }

    /// @inheritdoc IDebtEngine
    function burn(address from, uint256 amount) external override {
        require(msg.sender == vault, "DebtEngine: not vault");
        stablecoin.burn(from, amount);
        _totalDebt -= amount;
    }

    /// @notice Increases the debt balance for a vault.
    /// @dev Only callable by the vault.
    function increaseDebt(uint256 vaultId, uint256 amount) external {
        require(msg.sender == vault, "DebtEngine: not vault");
        _vaultDebt[vaultId] += amount;
    }

    /// @notice Decreases the debt balance for a vault.
    /// @dev Only callable by the vault.
    function decreaseDebt(uint256 vaultId, uint256 amount) external {
        require(msg.sender == vault, "DebtEngine: not vault");
        _vaultDebt[vaultId] -= amount;
    }

    /// @inheritdoc IDebtEngine
    function debtOf(uint256 vaultId) external view override returns (uint256) {
        return _vaultDebt[vaultId];
    }

    /// @inheritdoc IDebtEngine
    function totalDebt() external view override returns (uint256) {
        return _totalDebt;
    }
}