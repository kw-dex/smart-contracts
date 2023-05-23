// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/utils/Ownable.sol";
import "contracts/tokens/KERC20.sol";

contract TokenFactory is Ownable {
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
        KERC20 token = new KERC20(symbol, name, decimals, msg.sender);

        emit TokenDeployed(msg.sender, address(token));

        _deployedTokens.push(address(token));
        return address(token);
    }

    function deployedTokens() external view returns (address[] memory) {
        return _deployedTokens;
    }
}