// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IKPoolEvents {
    event Deposit(address indexed from, address indexed token, uint256 amount);

    event Withdraw(address indexed to, address indexed token, uint256 amount);

    event Exchange(address indexed fromToken, address indexed toToken, uint256 amountSpend, uint256 amountReceived);

    event RewardsWithdrawn(address indexed to, uint256 token0, uint256 token1);
}