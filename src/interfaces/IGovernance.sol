// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGovernance {
    function initGovernance(address[] memory membets, uint256 threshold) external;
    function getThreshold() external returns (uint256);
    function setThreshold(uint256 threshold) external;
    function addMember(address owner) external;
}
