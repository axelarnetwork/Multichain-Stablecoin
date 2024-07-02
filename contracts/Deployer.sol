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

    /*****************\
     INITIALIZATION
  /*****************/

    function initialize(IInterchainTokenService _its, AccessControl _accessControl, IAxelarGateway _gateway) external initializer {
        s_its = _its;
        s_accessControl = _accessControl;
        s_gateway = _gateway;
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    //on dest chain deploy token manager for new ITS token
    function execute(bytes32 _commandId, string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload) external {
       // TODO!
    }

    ProxyAdmin public testMe;
    address public testMeImpl;

    bytes public testMeData;

    function upgradeSemiNativeToken(address _proxyAdmin) external {
        address newTokenImpl = _create3(
            type(SemiNativeTokenV2).creationCode,
            0x0000000000000000000000000000000000000000000000000000000000003039
        ); //12345

        if (newTokenImpl == address(0)) revert DeploymentFailed();
        testMeImpl = newTokenImpl;

        // Read the storage slot of proxy admin
        // bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

        ProxyAdmin(_proxyAdmin).upgradeAndCall(s_tokenProxy, testMeImpl, '');
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
