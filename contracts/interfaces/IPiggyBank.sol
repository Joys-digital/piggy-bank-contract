// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPiggyBank {
    function accruePrimeRewawd() external payable returns(bool success);
}