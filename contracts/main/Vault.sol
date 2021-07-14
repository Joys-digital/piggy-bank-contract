// SPDX-License-Identifier: MIT
// solhint-disable not-rely-on-time, reason-string, no-inline-assembly]

pragma solidity 0.6.12;

import "../utils/PiggyBankOwnable.sol";

/**
 * @dev Vault for Piggy Bank contract
 */
contract Vault is PiggyBankOwnable {
    event VaultReplenishment(address indexed from, uint256 amount, uint256 timestamp);
    event VaultWithdraw(address indexed from, uint256 amount, uint256 timestamp);

    receive() external payable {
        emit VaultReplenishment(msg.sender, msg.value, block.timestamp);
    }

    function vaultWithdraw(uint256 amount) external onlyOwner returns(bool) {
        require(amount <= address(this).balance, "Vault: insufficient funds in the vault");

        msg.sender.transfer(amount);

        emit VaultWithdraw(msg.sender, amount, block.timestamp);

        return true;
    }
}