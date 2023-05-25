// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOwnable {
    function transferOwnership(address to) external;

    function owner() external view returns (address);
}