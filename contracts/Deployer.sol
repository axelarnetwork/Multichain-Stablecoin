// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import '@axelar-network/interchain-token-service/contracts/interfaces/ITokenManagerType.sol';
import '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';

import './AccessControl.sol';
//TODO import semiNativeV2
import './SemiNativeTokenV2.sol';

import '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3.sol';

contract Deployer is Initializable, Create3 {
    using AddressBytes for address;

    /*************\
      ERRORS
  /*************/

    error DeploymentFailed();
    error NotApprovedByGateway();

    /*************\
      STORAGE
  /*************/
    IInterchainTokenService public s_its;
    AccessControl public s_accessControl;
    IAxelarGateway public s_gateway;
    ITransparentUpgradeableProxy public s_tokenProxy;

    bytes32 public S_SALT_ITS_TOKEN; //12345

    /*****************\
     INITIALIZATION
  /*****************/

    function initialize(IInterchainTokenService _its, AccessControl _accessControl, IAxelarGateway _gateway) external initializer {
        s_its = _its;
        s_accessControl = _accessControl;
        s_gateway = _gateway;

        S_SALT_ITS_TOKEN = 0x0000000000000000000000000000000000000000000000000000000000003039; //12345
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    //on dest chain deploy token manager for new ITS token
    function execute(bytes32 _commandId, string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload) external {
        // TODO!
        if (!s_gateway.validateContractCall(_commandId, _sourceChain, _sourceAddress, keccak256(_payload))) revert NotApprovedByGateway();

        (bytes32 computedTokenId, bytes memory semiNativeTokenBytecode, bytes4 semiNativeSelector) = abi.decode(
            _payload,
            (bytes32, bytes, bytes4)
        );

        address newTokenImpl = _create3(semiNativeTokenBytecode, 0x00000000000000000000000000000000000000000000000000000000000004D2);
        if (newTokenImpl == address(0)) revert DeploymentFailed();

        bytes memory creationCodeProxy = _getEncodedCreationCodeSemiNative(
            address(this),
            newTokenImpl,
            computedTokenId,
            semiNativeSelector
        );
        address newTokenProxy = _create3(creationCodeProxy, 0x000000000000000000000000000000000000000000000000000000000000007B);
        if (newTokenProxy == address(0)) revert DeploymentFailed();

        s_tokenProxy = ITransparentUpgradeableProxy(newTokenProxy);

        s_its.deployTokenManager(
            S_SALT_ITS_TOKEN,
            '',
            ITokenManagerType.TokenManagerType.MINT_BURN,
            abi.encode(msg.sender.toBytes(), newTokenProxy),
            0
        );

        s_gateway.callContract(_sourceChain, _sourceAddress, abi.encode(newTokenProxy));
    }

    function upgradeSemiNativeToken(address _proxyAdmin) external {
        address newTokenImpl = _create3(
            type(SemiNativeTokenV2).creationCode,
            0x00000000000000000000000000000000000000000000000000000000000005D2
        );
        if (newTokenImpl == address(0)) revert DeploymentFailed();

        ProxyAdmin(_proxyAdmin).upgradeAndCall(s_tokenProxy, newTokenImpl, '');
    }

    function _getEncodedCreationCodeSemiNative(
        address _proxyAdmin,
        address _implAddr,
        bytes32 _itsTokenId,
        bytes4 semiNativeSelector
    ) internal view returns (bytes memory proxyCreationCode) {
        //init func args
        bytes memory initData = abi.encodeWithSelector(semiNativeSelector, s_its, _itsTokenId);

        //concat bytecode + init func args
        proxyCreationCode = abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(_implAddr, _proxyAdmin, initData));
    }
}
