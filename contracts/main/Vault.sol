// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, reason-string, no-inline-assembly]

pragma solidity 0.6.12;

import "../utils/VaultOwnable.sol";
import "../interfaces/IPiggyBank.sol";

/**
 * @dev Vault for Piggy Bank contract
 */
contract Vault is VaultOwnable {
    event VaultReplenishment(address indexed from, uint256 amount, uint256 timestamp);
    event VaultWithdraw(address indexed from, uint256 amount, uint256 timestamp);

    receive() external payable {
        emit VaultReplenishment(msg.sender, msg.value, block.timestamp);
    }

    function vaultWithdraw(uint256 amount) external onlyOwner returns(bool) {
        require(amount <= address(this).balance, "Vault: insufficient funds in the vault");

        IPiggyBank(msg.sender).accruePrimeRewawd{value: amount}();

        emit VaultWithdraw(msg.sender, amount, block.timestamp);

        return true;
    }
}