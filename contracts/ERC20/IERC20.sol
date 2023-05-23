// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Token {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface KERC20Token is ERC20Token {
    function mint(uint256 amount) external returns (bool success);

    function burn(uint256 amount) external returns (bool success);

    function owner() external view returns (address);

    function transferOwnership(address to) external returns (bool success);

    event Mint(uint256 amount);

    event Burn(address indexed tokenOwner, uint256 amount);

    event TransferOwnership(address indexed from, address indexed to);
}