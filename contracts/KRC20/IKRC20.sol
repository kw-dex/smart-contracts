// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/Ownable/IOwnable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external;

    function approve(address spender, uint256 tokens) external;

    function transferFrom(address from, address to, uint256 tokens) external;

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface IKRC20 is IERC20, IOwnable {
    function approveUnlimited(address spender) external;

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint256);

    function revokeApproval(address spender) external;

    function transferCallData(address to, uint256 tokens, bytes[] calldata data) external;

    event Mint(uint256 amount);

    event Burn(address indexed tokenOwner, uint256 amount);

    error ExecutionError(address target, bytes[] callData, bytes reason);
}