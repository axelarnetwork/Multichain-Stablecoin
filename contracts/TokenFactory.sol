// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { AddressToString } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressString.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { StringToBytes32 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/Bytes32String.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import '@axelar-network/interchain-token-service/contracts/interfaces/ITokenManagerType.sol';
import '@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create3.sol';
import './NativeTokenV1.sol';
import './SemiNativeToken.sol';
import './AccessControl.sol';
import './Deployer.sol';

contract TokenFactory is Create3, Initializable {
    using AddressToString for address;
    using AddressBytes for address;
    using StringToBytes32 for string;

    /*************\
        ERRORS
    /*************/
    error DeploymentFailed();
    error OnlyAdmin();
    error NotApprovedByGateway();
    error TokenAlreadyDeployed();
    error InvalidChain();
    error InvalidToken();

    /*************\
        STORAGE
    /*************/
    IInterchainTokenService public s_its;
    AccessControl public s_accessControl;
    IAxelarGasService public s_gasService;
    IAxelarGateway public s_gateway;
    Deployer public s_deployer;
    bytes32 public S_SALT_ITS_TOKEN; //12345

    address public s_nativeToken;
    mapping(string => address) public s_semiNativeTokens;

    /*************\
        EVENTS
    /*************/
    event NativeTokenDeployed(address token, bytes32 interchainTokenId);

    /*************\
        MODIFIERS
    /*************/
    modifier onlyAdmin() {
        if (!s_accessControl.isAdmin(msg.sender)) revert OnlyAdmin();
        _;
    }

    /*************\
     INITIALIZATION
    /*************/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInterchainTokenService _its,
        IAxelarGasService _gasService,
        IAxelarGateway _gateway,
        AccessControl _accessControl,
        Deployer _deployer
    ) external initializer {
        s_its = _its;
        s_gasService = _gasService;
        s_gateway = _gateway;
        s_accessControl = _accessControl;
        s_deployer = _deployer;

        S_SALT_ITS_TOKEN = 0x0000000000000000000000000000000000000000000000000000000000003039; //12345
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    //crosschain semi native deployment (does not wire up to its)
    function deployRemoteSemiNativeToken(string calldata _destChain) external payable {
        if (s_semiNativeTokens[_destChain] != address(0) && s_nativeToken != address(0)) revert TokenAlreadyDeployed();

        bytes32 computedTokenId = keccak256(abi.encode(keccak256('its-interchain-token-id'), address(this), S_SALT_ITS_TOKEN));

        bytes memory gmpPayload = abi.encode(computedTokenId, type(SemiNativeToken).creationCode, SemiNativeToken.initialize.selector);

        s_gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            _destChain,
            address(s_deployer).toString(),
            gmpPayload,
            msg.sender
        );

        s_gateway.callContract(_destChain, address(s_deployer).toString(), gmpPayload);
    }

    // await contract.deployHomeNative(10000, 20000, {gasLimit: "10000000"})
    function deployHomeNative(uint256 _burnRate, uint256 _txFeeRate) external payable onlyAdmin returns (address newTokenProxy) {
        if (s_nativeToken != address(0)) revert TokenAlreadyDeployed();

        bytes32 SALT_PROXY = 0x000000000000000000000000000000000000000000000000000000000000007B; //123
        bytes32 SALT_IMPL = 0x00000000000000000000000000000000000000000000000000000000000004D2; //1234

        // Deploy implementation
        address newTokenImpl = _create3(type(NativeTokenV1).creationCode, SALT_IMPL);
        if (newTokenImpl == address(0)) revert DeploymentFailed();

        // Generate Proxy Creation Code (Bytecode + Constructor)
        bytes memory proxyCreationCode = _getEncodedCreationCodeNative(msg.sender, newTokenImpl, _burnRate, _txFeeRate);

        // Deploy proxy
        newTokenProxy = _create3(proxyCreationCode, SALT_PROXY);
        if (newTokenProxy == address(0)) revert DeploymentFailed();
        s_nativeToken = newTokenProxy;

        // Deploy ITS
        bytes32 tokenId = s_its.deployTokenManager(
            S_SALT_ITS_TOKEN,
            '',
            ITokenManagerType.TokenManagerType.LOCK_UNLOCK,
            abi.encode(msg.sender.toBytes(), newTokenProxy),
            msg.value
        );

        emit NativeTokenDeployed(newTokenProxy, tokenId);
    }

    function execute(bytes32 _commandId, string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload) external {
        // TODO!
        if (!s_gateway.validateContractCall(_commandId, _sourceChain, _sourceAddress, keccak256(_payload))) revert NotApprovedByGateway();
        s_semiNativeTokens[_sourceChain] = abi.decode(_payload, (address));
    }

    function getExpectedAddress(bytes32 _salt) public view returns (address) {
        return _create3Address(_salt);
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _getEncodedCreationCodeNative(
        address _proxyAdmin,
        address _implAddr,
        uint256 _burnRate,
        uint256 _txFeeRate
    ) internal view returns (bytes memory proxyCreationCode) {
        bytes memory initData = abi.encodeWithSelector(NativeTokenV1.initialize.selector, s_accessControl, s_its, _burnRate, _txFeeRate);

        proxyCreationCode = abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(_implAddr, _proxyAdmin, initData));
    }
}
