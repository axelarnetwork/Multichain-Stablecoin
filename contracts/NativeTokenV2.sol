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
contract NativeTokenV2 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, ERC20PermitUpgradeable {
    /*************\
        ERRORS
    /*************/
    error OnlyAdmin();
    error Blacklisted();
    error NotApprovedByGateway();
    error InvalidSendAmount();

    /*************\
        STORAGE
    /*************/
    AccessControl public s_accessControl;
    IInterchainTokenService public s_its;
    bytes32 public s_tokenId;

    uint256 public s_burnRate;
    uint256 public s_txFeeRate;
    uint256 private s_rewardPool;

    /*************\
        EVENTS
    /*************/
    event RewardAdded(uint256 _amount);
    event RewardClaimed(address _claimer, uint256 _amount);

    /*************\
       MODIFIERS
    /*************/

    modifier isAdmin() {
        if (!s_accessControl.isAdmin(msg.sender)) revert OnlyAdmin();
        _;
    }

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
        uint256 _burnRate,
        uint256 _txFeeRate
    ) public initializer {
        __ERC20_init('Interchain Token', 'ITS');
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __ERC20Permit_init('Interchain Token');

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

    function setBurnRate(uint256 newBurnRate) external whenNotPaused isAdmin {
        s_burnRate = newBurnRate;
    }

    function setTxFee(uint256 newRewardRate) external whenNotPaused isAdmin {
        s_txFeeRate = newRewardRate;
    }

    function mint(address _to, uint256 _amount) public whenNotPaused isBlacklisted(_to) {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

    function claimRewards() external whenNotPaused {
        uint256 reward = _calculateReward(msg.sender);
        s_rewardPool -= reward;
        _mint(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function isTokenV2() external pure returns (bool) {
        return true;
    }

    /***************************\
       INTERNAL FUNCTIONALITY
    \***************************/

    function _calculateReward(address _account) internal view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (s_rewardPool * balanceOf(_account)) / totalSupply();
    }

    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) whenNotPaused {
        uint256 burnAmount = (_value * s_burnRate) / 1e16;
        uint256 fee = (_value * s_txFeeRate) / 1e16;

        uint256 amountToSend = _value - fee - burnAmount;

        if (burnAmount > 0) _burn(_from, burnAmount);

        if (amountToSend + burnAmount + fee != _value) revert InvalidSendAmount();
        ERC20Upgradeable._update(_from, _to, _value);
        s_rewardPool += fee;
        emit RewardAdded(fee);
    }
}
