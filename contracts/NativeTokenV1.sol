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

    uint256 public s_burnRate;
    uint256 public s_txFeeRate;

    uint256 public s_rewardPool;

    /*************\
        EVENTS
    /*************/
    event RewardAdded(uint256 _fee);
    event RewardClaimed(address _receipient, uint256 _reward);

    /*************\
       MODIFIERS
    /*************/
    modifier isAdmin() {
        if (s_accessControl.isAdmin(msg.sender)) revert OnlyAdmin();
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
        uint256 _burnRate,
        uint256 _txFeeRate
    ) public initializer {
        __ERC20_init('Multichain USD', 'USD');
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __ERC20Permit_init('Multichain USD');

        s_accessControl = _accessControl;
        s_its = _its;

        s_burnRate = _burnRate;
        s_txFeeRate = _txFeeRate;
    }

    /***************************\
       EXTERNAL FUNCTIONALITY
    \***************************/

    function pause() external isAdmin {
        _pause();
    }

    function unpause() external isAdmin {
        _unpause();
    }

    function setBurnRate(uint256 _newBurnRate) external isAdmin whenNotPaused {
        s_burnRate = _newBurnRate;
    }

    function setTxFeeRate(uint256 _newTxFee) external isAdmin whenNotPaused {
        s_txFeeRate = _newTxFee;
    }

    // > await contract.mint("0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE", "7000000000000000000", {gasLimit: "10000000"})
    function mint(address _to, uint256 _amount) public whenNotPaused {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public whenNotPaused {
        _burn(_from, _amount);
    }

    function claimReward() external whenNotPaused {
        uint256 reward = _calculateReward(msg.sender);
        s_rewardPool -= reward;
        _mint(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/
    function _calculateReward(address _account) internal view returns (uint256) {
        return (s_rewardPool * balanceOf(_account)) / totalSupply();
    }

    function _update(address _from, address _to, uint256 _value) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        //if minting
        if (_from == address(0)) {
            ERC20Upgradeable._update(_from, _to, _value);
            return;
        }

        uint256 burnAmount = (_value * s_burnRate) / 1e18;
        uint256 fee = (_value * s_txFeeRate) / 1e18;

        uint256 amountToSend = _value - fee - burnAmount;

        if (burnAmount > 0) _burn(_from, burnAmount);

        if (amountToSend + burnAmount + fee != _value) revert InvalidSendAmount();

        s_rewardPool += fee;

        ERC20Upgradeable._update(_from, _to, _value);

        emit RewardAdded(fee);
    }
}
