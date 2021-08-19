// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IPartner {
    function addPartner(address payable _newPartner, address payable _parentOfPartner) external;

    function deactivatePartner(address payable _deactivablePartner) external;

    function changePartnerStatus(address payable _partner, uint256 _newStatus) external;

    function getPartner(address _partner) external view returns(bool, uint256, address payable, uint256, string memory);

    function getChild(address _partner, uint256 index) external view returns(address payable);

    function getParentList(address _partner) external view returns(address payable[] memory);

    function getChildList(address _partner) external view returns(address payable[] memory);
}