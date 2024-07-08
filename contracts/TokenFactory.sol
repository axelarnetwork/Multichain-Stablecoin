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
import './NativeToken.sol';
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
        // TODO
    }

    function deployHomeNative(uint256 _burnRate, uint256 _txFeeRate) external payable onlyAdmin returns (address newTokenProxy) {
        // TODO
    }

    function execute(bytes32 _commandId, string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload) external {
        // TODO!
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
        // TODO
    }
}
