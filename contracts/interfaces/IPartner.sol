// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IPartner {
    function getPartner(address _partner) external view returns(bool, uint256, address payable, uint256, string memory);
}