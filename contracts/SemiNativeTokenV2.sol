// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';

import '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol';

import './NativeToken.sol';

contract SemiNativeTokenV2 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    using AddressBytes for bytes;

    /*************\
        ERRORS
    /*************/
    error OnlyAdmin();
    error OnlyTokenManager();
    error Blacklisted();
    error NotApprovedByGateway();

    /*************\
        STORAGE
    /*************/
    IInterchainTokenService public s_its;
    bytes32 public s_tokenId;

    /*************\
       MODIFIERS
    /*************/

    modifier isBlacklisted(address _receiver) {
        // From Chainanalysis doc
        // SanctionsList sanctionsList = SanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);
        // bool isToSanctioned = sanctionsList.isSanctioned(to);
        _;
    }

    /*************\
     INITIALIZATION
    /*************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //TODO fix init
    function initialize() public /*initializer*/ {
        __ERC20_init('Semi Native Interchain Token', 'SITS');
        __ERC20Burnable_init();
        s_its = IInterchainTokenService(address(0)); //_its;
        s_tokenId = 'BEN'; //_itsTokenId;
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    function mint(address _to, uint256 _amount) public isBlacklisted(_to) {
        if (s_its.validTokenManagerAddress(s_tokenId) == address(0)) revert OnlyTokenManager();
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

    function interchainTransfer(
        string calldata _destChain,
        bytes calldata _receiver,
        uint256 _amount
    ) external payable isBlacklisted(_receiver.toAddress()) {
        s_its.interchainTransfer(s_tokenId, _destChain, _receiver, _amount, '', msg.value);
    }

    function isV2() public pure returns (bool) {
        return true;
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _update(address _from, address _to, uint256 _value) internal override(ERC20Upgradeable) {
        ERC20Upgradeable._update(_from, _to, _value);
    }
}
