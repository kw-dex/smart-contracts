// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Ownable {
    address _owner;

    event TransferOwnership(address indexed from, address indexed to);

    constructor () {
        _owner = msg.sender;
    }

    function transferOwnership(address to) external returns (bool) {
        require(_owner == msg.sender, "Not an owner");

        _owner = to;

        emit TransferOwnership(msg.sender, to);
        return true;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}