// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title USDa Stablecoin
/// @notice Minimal ERC20 token representing the stablecoin minted by the DebtEngine.
///         Includes ERC20 Permit (EIP-2612) for gasless approvals.
///         Only the DebtEngine may call mint and burn.
contract Stablecoin is ERC20, ERC20Permit, Ownable {
    address public debtEngine;

    event DebtEngineUpdated(address indexed oldEngine, address indexed newEngine);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
        Ownable(msg.sender)
    {}

    modifier onlyDebtEngine() {
        require(msg.sender == debtEngine, "Stablecoin: not debt engine");
        _;
    }

    /// @notice Sets the DebtEngine allowed to mint/burn.
    /// @dev For safety, this should be called once during deployment, or through a timelock in production.
    function setDebtEngine(address _debtEngine) external onlyOwner {
        require(_debtEngine != address(0), "Stablecoin: zero address");
        emit DebtEngineUpdated(debtEngine, _debtEngine);
        debtEngine = _debtEngine;
    }

    /// @notice Mint USDa.
    function mint(address to, uint256 amount) external onlyDebtEngine {
        _mint(to, amount);
    }

    /// @notice Burn USDa from an account (no allowance needed; restricted to DebtEngine).
    function burn(address from, uint256 amount) external onlyDebtEngine {
        _burn(from, amount);
    }
}
