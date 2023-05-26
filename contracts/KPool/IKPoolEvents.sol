// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IKPoolEvents {
    event Deposit(address indexed from, uint256 amount0, uint256 amount1);

    event Withdraw(address indexed to, uint256 amount0, uint256 amount1);

    event Exchange(address indexed fromToken, address indexed toToken, uint256 amountSpend, uint256 amountReceived);

    event ClaimRewards(address indexed to, uint256 token0, uint256 token1);
}