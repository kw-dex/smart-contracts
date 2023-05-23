// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/utils/Ownable.sol";
import "contracts/tokens/KERC20.sol";

contract KPool is Ownable {
    KERC20 _token0;
    KERC20 _token1;

    mapping (address => mapping(address => uint256)) deposits;

    constructor (
        address _poolToken0Address,
        address _poolToken1Address,
        address _poolOwner
    ) {
        _token0 = KERC20(_poolToken0Address);
        _token1 = KERC20(_poolToken1Address);
        _owner = _poolOwner;
    }

    function depositTokens(uint256 _token0Amount, uint256 _token1Amount) external returns (bool) {
        require(_token0.allowance(msg.sender, address(this)) >= _token0Amount && _token1.allowance(msg.sender, address(this)) >= _token1Amount, "Not enough allowance");

        _token0.transferFrom(msg.sender, address(this), _token0Amount);
        _token1.transferFrom(msg.sender, address(this), _token1Amount);

        deposits[msg.sender][address(_token0)] = deposits[msg.sender][address(_token0)] + _token0Amount;
        deposits[msg.sender][address(_token1)] = deposits[msg.sender][address(_token1)] + _token1Amount;

        return true;
    }

    function withdrawToken(KERC20 token, uint256 amount) public returns (bool) {
        require(deposits[msg.sender][address(token)] > amount, "Not enough deposit");
        require(token.balanceOf(address(this)) > amount, "Not enough pool balance");

        token.transfer(msg.sender, amount);

        deposits[msg.sender][address(token)] = deposits[msg.sender][address(token)] - amount;

        return true;
    }

    function exchangeToken0(uint256 amount) external returns (bool) {
        uint256 exchangeRate = this.calcRate(amount);

        uint256 token1Amount = exchangeRate / 1000000;

        require(token1Amount > 0, "Invalid exchange amount");
        require(_token0.allowance(msg.sender, address(this)) >= amount, "Not enoug allowance");

        _token0.transferFrom(msg.sender, address(this), amount);
        _token1.transfer(msg.sender, token1Amount);

        return true;
    }

    function calcRate(uint256 amount) external view returns (uint) {
        uint exchangeRate = (amount * 1000) * (((_token1.balanceOf(address(this)) * 1000 / _token0.balanceOf(address(this)))));

        return exchangeRate;
    }
}