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

contract NativeTokenV1 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, ERC20PermitUpgradeable {
    /*************\
        ERRORS
    /*************/
    error InvalidSendAmount();
    error OnlyAdmin();
    error InvalidReceiver();

    /*************\
        STORAGE
    /*************/
    AccessControl public s_accessControl;
    IInterchainTokenService public s_its;

    /*************\
        EVENTS
    /*************/
    event RewardAdded(uint256 _fee);
    event RewardClaimed(address _receipient, uint256 _reward);

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
        __ERC20_init('USD Token', 'USD');
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __ERC20Permit_init('USD Token');
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

    function mint(address _to, uint256 _amount) public whenNotPaused {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public whenNotPaused {
        _burn(_from, _amount);
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _update(address _from, address _to, uint256 _value) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        ERC20Upgradeable._update(_from, _to, _value);
    }
}
