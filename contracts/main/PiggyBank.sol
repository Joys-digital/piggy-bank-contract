// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, reason-string, no-inline-assembly

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utils/PiggyBankOwnable.sol";

/**
 * @dev 'piggy bank' contract for accumulation of gift currency
 */
contract PiggyBank is PiggyBankOwnable {
    using SafeMath for uint256;

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

    constructor(address newBasePlatform) public {
        _basePlatform = newBasePlatform;
    }

    receive() external payable {

    }

    function changeBasePlatform(address newBasePlatform) external onlyOwner returns(bool success) {
        _basePlatform = newBasePlatform;
        return true;
    }

    function makePrimeReward(address target) external returns(bool success) {
        require(msg.sender == _basePlatform);
        require(msg.sender == _basePlatform);

        User memory user = _user[target];
        if (user.isPrimeRewarded == false) {
            user.balance = user.balance.add(100 ether);
            // call to vault
            _totalBalance = _totalBalance.add(100 ether);
            user.isPrimeRewarded = true;
            _user[target] = user;
        }
        return true;
    } 

    function setVerificationStatus(address target, bool isVerified) external onlyOwner returns(bool success) {
        _user[target].isVerified = isVerified;
        return true;
    }

    function withdraw(address payable target, uint256 amount) external onlyOwner returns(bool success) {
        _recalculateUser(target);
        
        _user[target].balance = _user[target].balance.sub(amount);

        _transfer(target, amount);
        
        return true;
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

        // emit Transfer(target, amount, block.timestamp);   
    }
    








}
