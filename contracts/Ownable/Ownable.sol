// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/IOwnable.sol";

contract Ownable is IOwnable {
    address _owner;

    event TransferOwnership(address indexed from, address indexed to);

    modifier onlyOwner {
        require(msg.sender == _owner, "Not an owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    function transferOwnership(address to) external onlyOwner returns (bool) {
        _owner = to;

        emit TransferOwnership(msg.sender, to);
        return true;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}