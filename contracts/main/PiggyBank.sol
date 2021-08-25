// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, reason-string, no-inline-assembly

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Vault.sol";
import "../interfaces/IMLMstructure.sol";
import "../interfaces/IPartner.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPiggyBank.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev 'piggy bank' contract for accumulation of gift currency
 */
contract PiggyBank is IPiggyBank, OwnableUpgradeable {
    using SafeMath for uint256;

    event Receive(address indexed from, uint256 value, uint256 timestamp);
    event AccruePrimeRewawd(address indexed from, uint256 value, uint256 timestamp);
    event Transfer(address indexed target, uint256 value, uint256 timestamp);
    event HookPrimeReward(address indexed from, address indexed target, uint256 value, uint256 timestamp);
    event SetVerificationStatus(address indexed owner, address indexed target, bool status, uint256 timestamp);
    event Withdraw(address indexed from, uint256 value, uint256 timestamp);
    event ChangeBasePlatform(address indexed newBasePlatform, address indexed oldBasePlatform, uint256 timestamp);

    struct User {
        bool isVerified;
        bool isPrimeRewarded;
        uint256 personalAccrual;
        uint256 balance;
    }

    uint256 internal _totalAccrual;
    uint256 internal _totalBalance;
    uint256 internal _totalVerifiedFree;
    mapping(address => User) internal _user;

    address internal _basePlatform;
    address internal _vault;

    function initialize(address newBasePlatform) public initializer {
        __Ownable_init();
        _basePlatform = newBasePlatform;
        _vault = address(new Vault());
    }

    receive() external payable {
        uint256 freePartnerCount = _totalVerifiedFree;
        require(freePartnerCount > 0, "PiggyBank: no verified-free partners.");
        _totalAccrual = _totalAccrual.add(msg.value.div(freePartnerCount));
        _totalBalance = _totalBalance.add(msg.value);

        emit Receive(msg.sender, msg.value, block.timestamp);
    }

    function accruePrimeRewawd() external payable override returns(bool success) {
        require(msg.sender == _vault, "PiggyBank: msg.sender must be Vault contract.");
        require(msg.value > 0, "PiggyBank: msg.value must be > 0.");

        emit AccruePrimeRewawd(msg.sender, msg.value, block.timestamp);

        return true;
    }

    function hookPrimeReward(address target) external override returns(bool success) {
        require(msg.sender == _basePlatform, "PiggyBank: msg.sender must be MLMStricture contract.");

        _recalculateUser(target);

        User memory user = _user[target];
        if (user.isPrimeRewarded == false) {
            // delete free
            (,uint256 status,,,) = IPartner(_basePlatform).getPartner(target);
            if ((status == 1) && _user[target].isVerified) {
                _totalVerifiedFree = _totalVerifiedFree.sub(1);
            }

            // calculate cost of 100 rubles (to JOYS)
            uint256 primeReward = IMLMstructure(_basePlatform).primeStatusCost().mul(100).div(1600);

            // withfraw 100 roubles
            IVault(_vault).vaultWithdraw(primeReward);

            // save state
            user.balance = user.balance.add(primeReward);
            _totalBalance = _totalBalance.add(primeReward);
            user.isPrimeRewarded = true;
            _user[target] = user;

            emit HookPrimeReward(msg.sender, target, primeReward, block.timestamp);
        }

        return true;
    } 

    function setVerificationStatus(address target, bool isVerified) external onlyOwner returns(bool success) {
        _recalculateUser(target);

        (,uint256 status,,,) = IPartner(_basePlatform).getPartner(target);
        if (status == 1) {
            _totalVerifiedFree = _totalVerifiedFree.add(1);
        }

        _user[target].isVerified = isVerified;

        emit SetVerificationStatus(msg.sender, target, isVerified, block.timestamp);

        return true;
    }

    function withdraw(address payable target, uint256 amount) external onlyOwner returns(bool success) {
        require(_user[target].isVerified == true, "PiggyBank: user must be verifyed.");
        _recalculateUser(target);
        
        _user[target].balance = _user[target].balance.sub(amount, "PiggyBank: withdrawal amount exceeds balance.");
        _totalBalance = _totalBalance.sub(amount, "PiggyBank: withdrawal amount exceeds total balance.");

        _transfer(target, amount);

        emit Withdraw(target, amount, block.timestamp);
        
        return true;
    }

    function changeBasePlatform(address newBasePlatform) external onlyOwner returns(bool success) {
        emit ChangeBasePlatform(newBasePlatform, _basePlatform, block.timestamp);

        _basePlatform = newBasePlatform;

        return true;
    }

    function totalAccrual() external view returns(uint256) {
        return(_totalAccrual);
    }

    function totalBalance() external view returns(uint256) {
        return(_totalBalance);
    }

    function totalVerifiedFree() external view returns(uint256) {
        return(_totalVerifiedFree);
    }

    function isPrimeRewarded(address target) external view returns(bool) {
        return(_user[target].isPrimeRewarded);
    }

    function isVerified(address target) external view returns(bool) {
        return(_user[target].isVerified);
    }

    function user(address target) external view returns(User memory) {
        return(_user[target]);
    }

    function basePlatform() external view returns(address) {
        return(_basePlatform);
    }

    function vault() external view returns(address) {
        return(_vault);
    }

    function balanceOf(address target) external view returns(uint256) {
        return(_user[target].balance.add(_expectedReward(target)));
    }

    function clearBalanceOf(address target) external view returns(uint256) {
        return(_user[target].balance);
    }

    function expectedRewardOf(address target) external view returns(uint256) {
        return(_expectedReward(target));
    }

    function _expectedReward(address target) internal view returns(uint256) {
        User memory usr = _user[target];
        if (usr.isVerified == true && usr.personalAccrual > 0 && usr.isPrimeRewarded == false) {
            return(_totalAccrual.sub(usr.personalAccrual));
        } else {
            return 0;
        }
    }

    function _recalculateUser(address target) internal {
        uint256 expectedRwd = _expectedReward(target);
        if (expectedRwd > 0) {
            _user[target].balance = _user[target].balance.add(expectedRwd);
        }
        _user[target].personalAccrual = _totalAccrual;
    }

    function _transfer(address payable target, uint256 amount) internal {
        target.transfer(amount);

        emit Transfer(target, amount, block.timestamp);   
    }

}
