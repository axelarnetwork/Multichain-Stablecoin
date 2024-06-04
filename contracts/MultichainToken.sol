// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';

// import "@axelar-network/interchain-token-service/interfaces/IInterchainTokenExecutable.sol";
import '@axelar-network/interchain-token-service/contracts/interfaces/IInterchainTokenService.sol';

import './NativeTokenV1.sol';

contract MultichainToken is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable
{
  using AddressBytes for bytes;

  /*************\
        ERRORS
    /*************/
  error OnlyAdmin();
  error Blacklisted();
  error NotApprovedByGateway();

  /*************\
        STORAGE
    /*************/
  AccessControl public s_accessControl;
  IInterchainTokenService public s_its;
  bytes32 public s_tokenId;

  /*************\
        EVENTS
    /*************/
  event TokenClaimed(uint256 amount, address claimer);

  /*************\
       MODIFIERS
    /*************/

  modifier isBlacklisted(address _receiver) {
    if (s_accessControl.isBlacklistedReceiver(_receiver)) revert Blacklisted();
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
    AccessControl _accessControl,
    IInterchainTokenService _its,
    bytes32 _itsTokenId
  ) public initializer {
    __ERC20_init('Semi Native Interchain Token', 'SITS');
    __ERC20Burnable_init();
    s_accessControl = _accessControl;
    s_its = _its;
    s_tokenId = _itsTokenId;
  }

  /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

  function mint(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public {
    _burn(_from, _amount);
  }

  //for crosschain tx FROM native || from non native
  function interchainTransfer(
    string calldata _destChain,
    bytes calldata _receiver,
    uint256 _amount
  ) external payable isBlacklisted(_receiver.toAddress()) {
    s_its.interchainTransfer(
      s_tokenId,
      _destChain,
      _receiver,
      _amount,
      '',
      msg.value
    );
  }

  /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

  function _update(
    address _from,
    address _to,
    uint256 _value
  ) internal override(ERC20Upgradeable) {
    ERC20Upgradeable._update(_from, _to, _value);
  }
}
