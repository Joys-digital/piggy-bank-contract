// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IMLMstructure {
    function primeStatusCost() external returns(uint256);
    function totalZero() external returns(uint256);
    function totalFree() external returns(uint256);
    function totalFreeTsc() external returns(uint256);
    function totalPrime() external returns(uint256);
}