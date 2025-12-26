// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../interfaces/ISessionManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SessionPermissionVerifier
/// @notice Simplified session manager implementing ERC‑7715 style permission checks.
/// Users can grant granular permissions to agents or externally owned callers.  The
/// verifier stores a list of allowed targets and function selectors for a
/// session along with an optional expiry.  This is a toy implementation and
/// should be extended before production use.
contract SessionPermissionVerifier is ISessionManager, Ownable {
    struct Permission {
        address target;
        bytes4 selector;
        uint256 expiry;
        bool exists;
    }

    // user => permissionId => permission
    mapping(address => mapping(uint256 => Permission)) public permissions;
    // user => next permission id
    mapping(address => uint256) public nextPermissionId;

    event PermissionGranted(address indexed user, uint256 indexed id, address target, bytes4 selector, uint256 expiry);
    event PermissionRevoked(address indexed user, uint256 indexed id);
    
    constructor() Ownable(msg.sender) {}

    /// @notice Grants a new permission.  The caller becomes the owner of the permission.
    /// @param target The contract to call.
    /// @param selector The function signature selector to allow.
    /// @param expiry A timestamp when the permission expires.  Set to 0 for no expiry.
    function grantPermission(address target, bytes4 selector, uint256 expiry) external {
        uint256 id = nextPermissionId[msg.sender]++;
        permissions[msg.sender][id] = Permission({target: target, selector: selector, expiry: expiry, exists: true});
        emit PermissionGranted(msg.sender, id, target, selector, expiry);
    }

    /// @notice Revokes a previously granted permission.
    function revokePermission(uint256 id) external {
        require(permissions[msg.sender][id].exists, "SessionPermissionVerifier: no permission");
        delete permissions[msg.sender][id];
        emit PermissionRevoked(msg.sender, id);
    }

    /// @inheritdoc ISessionManager
    function verify(address user, address target, bytes calldata data) external view override returns (bool allowed) {
        bytes4 selector;
        if (data.length >= 4) {
            // extract the first 4 bytes of the calldata (function selector)
            // data.offset is the pointer into calldata where `data` begins
            assembly {
                selector := shr(224, calldataload(data.offset))
            }
        }
        uint256 count = nextPermissionId[user];
        for (uint256 i = 0; i < count; i++) {
            Permission memory perm = permissions[user][i];
            if (!perm.exists) continue;
            if (perm.target == target && perm.selector == selector) {
                if (perm.expiry == 0 || perm.expiry >= block.timestamp) {
                    return true;
                }
            }
        }
        return false;
    }
}