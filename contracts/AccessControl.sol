// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract AccessControl is AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant BLACKLIST_ADMIN_ROLE = keccak256('BLACKLIST_ADMIN_ROLE');

    // eligible minters
    mapping(address => bool) private _minterAddresses;

    // blacklisted (receiver) addresses
    mapping(address => bool) private _blacklistedAddresses;

    function initialize(address _defaultAdmin) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, _defaultAdmin);
        _grantRole(BLACKLIST_ADMIN_ROLE, _defaultAdmin);
    }

    function addAdminRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function removeAddminRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function addNewMinter(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _minterAddresses[_address] = true;
    }

    function removeMinter(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _minterAddresses[_address] = false;
    }

    function addToBlacklist(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklistedAddresses[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklistedAddresses[_address] = false;
    }

    function isAdmin(address _address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function isWhitelistedMinter(address _address) external view returns (bool) {
        return _minterAddresses[_address];
    }

    function isBlacklistedReceiver(address _address) external view returns (bool) {
        return _blacklistedAddresses[_address];
    }
}
