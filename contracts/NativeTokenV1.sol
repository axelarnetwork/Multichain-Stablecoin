// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol';
import './AccessControl.sol';
import './SemiNativeToken.sol';

//TODO Inherit from InterchainTokenStandard
contract NativeTokenV1 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, ERC20PermitUpgradeable {
    /*************\
        ERRORS
    /*************/

    /*************\
        STORAGE
    /*************/

    /*************\
        EVENTS
    /*************/

    /*************\
       MODIFIERS
    /*************/

    /*************\
     INITIALIZATION
    /*************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init('Interchain Token', 'ITS');
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __ERC20Permit_init('Interchain Token');
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    // > await contract.mint("0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE", "7000000000000000000", {gasLimit: "10000000"})
    function mint(address _to, uint256 _amount) public whenNotPaused {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public whenNotPaused {
        _burn(_from, _amount);
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) whenNotPaused {}
}
