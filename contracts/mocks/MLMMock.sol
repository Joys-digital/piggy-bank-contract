// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IPartner.sol";
import "../interfaces/IPiggyBank.sol";
import "../interfaces/IMLMstructure.sol";


contract MLMMock is IPartner, IMLMstructure {

    address internal _piggyBank;

    constructor(address piggyBank) public {
        _piggyBank = piggyBank;
    }

    function getPartner(address partner) external view override returns(bool, uint256, address payable, uint256, string memory) {
        partner;
        return(true, 1, address(1), 1, "");
    }

    function primeHook(address target) external returns(bool) {
        IPiggyBank(_piggyBank).hookPrimeReward(target);
        return(true);
    }

    function primeStatusCost() external view override returns(uint256) {
        return 16 ether;
    }

}