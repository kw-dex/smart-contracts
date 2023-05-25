// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KRC20/IKRC20.sol";
import "contracts/KRC20/KRC20.sol";

contract KTokenFactory is Ownable {
    address[] _deployedTokens;

    event TokenDeployed(address indexed tokenOwner, address indexed tokenAddress);

    constructor() {
        _owner = msg.sender;
    }

    function deployToken(
        string memory symbol,
        string memory name,
        uint16 decimals
    ) external returns (address) {
        IKRC20 token = new KRC20(symbol, name, decimals, msg.sender);

        emit TokenDeployed(msg.sender, address(token));

        _deployedTokens.push(address(token));
        return address(token);
    }

    function deployedTokens() external view returns (address[] memory) {
        return _deployedTokens;
    }
}