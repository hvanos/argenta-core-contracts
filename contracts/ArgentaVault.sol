// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IArgentaVault.sol";
import "./interfaces/ICollateralRegistry.sol";
import "./interfaces/IDebtEngine.sol";
import "./interfaces/IOracleRouter.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/ISafetyGuard.sol";

/// @title ArgentaVault
/// @notice Main contract for managing Collateralised Debt Positions (CDPs).  Users
/// deposit collateral, borrow stablecoins and repay debt.  The vault
/// interacts with `CollateralRegistry` for risk parameters, `DebtEngine`
/// for mint/burn, `OracleRouter` for prices and `ISafetyGuard` for global
/// limits.
contract ArgentaVault is IArgentaVault, Ownable, ReentrancyGuard {
    using Address for address;

    struct Vault {
        address owner;
        bool active;
    }

    // next vault id
    uint256 public nextVaultId;
    // vaultId => Vault owner
    mapping(uint256 => Vault) public vaults;
    // vaultId => token => amount of collateral
    mapping(uint256 => mapping(address => uint256)) public collateralBalance;
    // vaultId => list of collateral tokens (to iterate when needed)
    mapping(uint256 => address[]) internal collateralTokens;
    // token => bool on vault's list to prevent duplicates
    mapping(uint256 => mapping(address => bool)) internal hasCollateralToken;

    ICollateralRegistry public collateralRegistry;
    IDebtEngine public debtEngine;
    IOracleRouter public oracle;
    ISafetyGuard public safetyGuard;
    IInterestRateModel public interestRateModel;

    event VaultOpened(uint256 indexed vaultId, address indexed owner);
    event CollateralAdded(uint256 indexed vaultId, address indexed token, uint256 amount, uint256 value);
    event CollateralRemoved(uint256 indexed vaultId, address indexed token, uint256 amount, uint256 value);
    event Borrowed(uint256 indexed vaultId, uint256 amount);
    event Repaid(uint256 indexed vaultId, uint256 amount);
    event VaultClosed(uint256 indexed vaultId);

    constructor(
        ICollateralRegistry _collateralRegistry,
        IDebtEngine _debtEngine,
        IOracleRouter _oracle,
        ISafetyGuard _safetyGuard,
        IInterestRateModel _interestRateModel
    ) Ownable(msg.sender) {
        collateralRegistry = _collateralRegistry;
        debtEngine = _debtEngine;
        oracle = _oracle;
        safetyGuard = _safetyGuard;
        interestRateModel = _interestRateModel;
    }

    /// @notice Opens a new vault and assigns ownership to the caller.
    function openVault() external override returns (uint256 vaultId) {
        vaultId = nextVaultId++;
        vaults[vaultId] = Vault({owner: msg.sender, active: true});
        emit VaultOpened(vaultId, msg.sender);
    }

    modifier onlyOwnerOf(uint256 vaultId) {
        require(vaults[vaultId].owner == msg.sender, "ArgentaVault: not vault owner");
        require(vaults[vaultId].active, "ArgentaVault: vault closed");
        _;
    }

    /// @inheritdoc IArgentaVault
    function addCollateral(uint256 vaultId, address token, uint256 amount) external payable override nonReentrant onlyOwnerOf(vaultId) {
        require(amount > 0 || msg.value > 0, "ArgentaVault: zero amount");
        // handle ETH deposit
        if (token == address(0)) {
            require(msg.value == amount, "ArgentaVault: mismatched ETH amount");
        } else {
            require(msg.value == 0, "ArgentaVault: ETH not expected");
        }
        // ensure supported collateral
        require(collateralRegistry.isSupported(token), "ArgentaVault: unsupported collateral");

        // compute USD value of deposit
        uint256 value = _valueOf(token, amount);

        // compute current vault collateral value
        uint256 currentValue = _getCollateralValueUSD(vaultId);

        // check guard
        require(safetyGuard.checkAddCollateral(currentValue, value), "ArgentaVault: collateral exceeds limit");

        // update balances
        if (token == address(0)) {
            // native token (ETH)
            collateralBalance[vaultId][address(0)] += amount;
        } else {
            // transfer ERC20
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            collateralBalance[vaultId][token] += amount;
        }

        // track token in list
        if (!hasCollateralToken[vaultId][token]) {
            hasCollateralToken[vaultId][token] = true;
            collateralTokens[vaultId].push(token);
        }
        emit CollateralAdded(vaultId, token, amount, value);
    }

    /// @inheritdoc IArgentaVault
    function removeCollateral(uint256 vaultId, address token, uint256 amount) external override nonReentrant onlyOwnerOf(vaultId) {
        require(amount > 0, "ArgentaVault: zero amount");
        uint256 bal = collateralBalance[vaultId][token];
        require(bal >= amount, "ArgentaVault: insufficient collateral");

        // temporarily decrease to check health factor
        collateralBalance[vaultId][token] = bal - amount;
        uint256 newHealth = getHealthFactor(vaultId);
        require(newHealth >= 1e18, "ArgentaVault: withdrawal would render vault undercollateralised");

        // update list if zero
        if (collateralBalance[vaultId][token] == 0) {
            hasCollateralToken[vaultId][token] = false;
            // remove from tokens array (swap and pop)
            uint256 len = collateralTokens[vaultId].length;
            for (uint256 i = 0; i < len; i++) {
                if (collateralTokens[vaultId][i] == token) {
                    collateralTokens[vaultId][i] = collateralTokens[vaultId][len - 1];
                    collateralTokens[vaultId].pop();
                    break;
                }
            }
        }

        // transfer out
        if (token == address(0)) {
            (bool sent,) = payable(msg.sender).call{value: amount}("");
            require(sent, "ArgentaVault: ETH transfer failed");
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
        uint256 value = _valueOf(token, amount);
        emit CollateralRemoved(vaultId, token, amount, value);
    }

    /// @inheritdoc IArgentaVault
    function borrow(uint256 vaultId, uint256 amount) external override nonReentrant onlyOwnerOf(vaultId) {
        require(amount > 0, "ArgentaVault: zero amount");
        // compute new debt
        uint256 currentDebt = debtEngine.debtOf(vaultId);
        uint256 totalSystemDebt = debtEngine.totalDebt();
        require(safetyGuard.checkBorrow(currentDebt, amount, totalSystemDebt), "ArgentaVault: borrow exceeds limits");
        // compute effective collateral value relative to risk params
        uint256 eff = _getEffectiveCollateral(vaultId);
        require(eff > 0, "ArgentaVault: no collateral");
        // new debt
        uint256 newDebt = currentDebt + amount;
        // require health factor after borrow >= 1
        uint256 healthAfter = (eff * 1e18) / newDebt;
        require(healthAfter >= 1e18, "ArgentaVault: borrow would undercollateralise");
        // update vault debt
        debtEngine.increaseDebt(vaultId, amount);
        // mint tokens to user
        debtEngine.mint(msg.sender, amount);
        emit Borrowed(vaultId, amount);
    }

    /// @inheritdoc IArgentaVault
    function repay(uint256 vaultId, uint256 amount) external override nonReentrant onlyOwnerOf(vaultId) {
        require(amount > 0, "ArgentaVault: zero amount");
        uint256 debt = debtEngine.debtOf(vaultId);
        require(debt >= amount, "ArgentaVault: repay exceeds debt");
        // burn tokens from sender
        debtEngine.burn(msg.sender, amount);
        debtEngine.decreaseDebt(vaultId, amount);
        emit Repaid(vaultId, amount);
    }

    /// @inheritdoc IArgentaVault
    function closeVault(uint256 vaultId) external override nonReentrant onlyOwnerOf(vaultId) {
        uint256 debt = debtEngine.debtOf(vaultId);
        if (debt > 0) {
            // user must have approved USDa for burn
            debtEngine.burn(msg.sender, debt);
            debtEngine.decreaseDebt(vaultId, debt);
            emit Repaid(vaultId, debt);
        }
        // return all collateral
        address[] storage tokens = collateralTokens[vaultId];
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 amt = collateralBalance[vaultId][t];
            if (amt > 0) {
                collateralBalance[vaultId][t] = 0;
                if (t == address(0)) {
                    (bool sent,) = payable(msg.sender).call{value: amt}("");
                    require(sent, "ArgentaVault: ETH transfer failed");
                } else {
                    IERC20(t).transfer(msg.sender, amt);
                }
                emit CollateralRemoved(vaultId, t, amt, _valueOf(t, amt));
            }
        }
        // mark vault inactive
        vaults[vaultId].active = false;
        emit VaultClosed(vaultId);
    }

    /// @inheritdoc IArgentaVault
    function getPosition(uint256 vaultId) external view override returns (uint256 collateralValue, uint256 debt) {
        collateralValue = _getCollateralValueUSD(vaultId);
        debt = debtEngine.debtOf(vaultId);
    }

    /// @inheritdoc IArgentaVault
    function getHealthFactor(uint256 vaultId) public view override returns (uint256) {
        uint256 debt = debtEngine.debtOf(vaultId);
        if (debt == 0) return type(uint256).max;
        uint256 eff = _getEffectiveCollateral(vaultId);
        return (eff * 1e18) / debt;
    }

    /// @dev Returns the current USD value of all collateral in a vault.
    function _getCollateralValueUSD(uint256 vaultId) internal view returns (uint256 total) {
        address[] storage tokens = collateralTokens[vaultId];
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 amt = collateralBalance[vaultId][t];
            if (amt == 0) continue;
            total += _valueOf(t, amt);
        }
    }

    /// @dev Returns the effective collateral available to cover debt.  Each
    /// collateral token is weighted by its MCR: eff = sum(value * 1e4 / mcr).
    function _getEffectiveCollateral(uint256 vaultId) internal view returns (uint256 eff) {
        address[] storage tokens = collateralTokens[vaultId];
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 amt = collateralBalance[vaultId][t];
            if (amt == 0) continue;
            uint256 value = _valueOf(t, amt);
            ICollateralRegistry.CollateralData memory params = collateralRegistry.getParams(t);
            // mcr is in basis points (e.g. 15000 = 150%).  Multiply by 1e4 for ratio.
            eff += (value * 10000) / params.mcr;
        }
    }

    /// @dev Returns the USD value of a given amount of token.
    function _valueOf(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = oracle.getPrice(token);
        uint256 decimals;
        if (token == address(0)) {
            decimals = 18;
        } else {
            decimals = IERC20Metadata(token).decimals();
        }
        // value = amount * price / 10**decimals
        return amount * price / (10 ** decimals);
    }

    // receive ETH
    receive() external payable {}
}