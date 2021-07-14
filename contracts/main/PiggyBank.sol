// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, reason-string, no-inline-assembly

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPiggyBank.sol";
import "../utils/PiggyBankOwnable.sol";

/**
 * @dev 'piggy bank' contract for accumulation of gift currency
 */
contract PiggyBank is IPiggyBank, PiggyBankOwnable {
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
    mapping(address => User) internal _user;

    address internal _basePlatform;
    address internal _vault;

    constructor(address newBasePlatform, address newVault) public {
        _basePlatform = newBasePlatform;
        _vault = newVault;
    }

    receive() external payable {
        uint256 freePartnerCount = 10;  // must be call to the base platform
        _totalAccrual = _totalAccrual.add(msg.value.div(freePartnerCount));
        _totalBalance = _totalBalance.add(msg.value);

        emit Receive(msg.sender, msg.value, block.timestamp);
    }

    function accruePrimeRewawd() external payable override returns(bool success) {
        require(msg.sender == _vault);
        require(msg.value > 0);

        emit AccruePrimeRewawd(msg.sender, msg.value, block.timestamp);

        return true;
    }

    function hookPrimeReward(address target) external returns(bool success) {
        require(msg.sender == _basePlatform);

        User memory user = _user[target];
        if (user.isPrimeRewarded == false) {
            // 100 ether must be received from a price oracle
            uint256 primeReward = 100 ether;
            IVault(_vault).vaultWithdraw(primeReward);
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

        _user[target].isVerified = isVerified;

        emit SetVerificationStatus(msg.sender, target, isVerified, block.timestamp);

        return true;
    }

    function withdraw(address payable target, uint256 amount) external onlyOwner returns(bool success) {
        _recalculateUser(target);
        
        _user[target].balance = _user[target].balance.sub(amount);

        _transfer(target, amount);

        emit Withdraw(target, amount, block.timestamp);
        
        return true;
    }

    function changeBasePlatform(address newBasePlatform) external onlyOwner returns(bool success) {
        emit ChangeBasePlatform(newBasePlatform, _basePlatform, block.timestamp);

        _basePlatform = newBasePlatform;

        return true;
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
        User memory user = _user[target];
        if (user.isVerified == true && user.personalAccrual > 0) {
            return(_totalAccrual.sub(user.personalAccrual));
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
