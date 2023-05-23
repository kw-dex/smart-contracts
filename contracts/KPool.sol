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

    function withdrawToken(address tokenAddress, uint256 amount) public returns (bool) {
        KERC20 token = KERC20(tokenAddress);

        require(deposits[msg.sender][tokenAddress] >= amount, "Not enough deposit");
        require(token.balanceOf(address(this)) >= amount, "Not enough pool balance");

        token.transfer(msg.sender, amount);

        deposits[msg.sender][tokenAddress] = deposits[msg.sender][tokenAddress] - amount;

        return true;
    }

    function exchangeTokens(bool ltr, uint256 amount) external returns (bool) {
        uint256 tokenAmount = this.estimateExchangeAmount(ltr, amount) / 1000000;

        require(tokenAmount > 0, "Invalid exchange amount");
        require(_token0.allowance(msg.sender, address(this)) >= amount, "Not enoug allowance");

        _token0.transferFrom(msg.sender, address(this), amount);
        _token1.transfer(msg.sender, tokenAmount);

        return true;
    }

    function isLTR(address _token0Address) external view returns (bool) {
        if (_token0Address == address(_token0)) return true;

        return false;
    }

    function estimateExchangeAmount(bool ltr, uint256 amount) external view returns (uint) {
        uint token1Exchange = (amount * 1000) * (_token1.balanceOf(address(this)) * 1000 / _token0.balanceOf(address(this)));
        uint token0Exchange = (amount * 1000) * (_token0.balanceOf(address(this)) * 1000 / _token1.balanceOf(address(this)));

        return ltr ? token1Exchange : token0Exchange;
    }

    function token0() external view returns (address) {
        return address(_token0);
    }

    function token1() external view returns (address) {
        return address(_token1);
    }

    function getBalances(address depositOwner) external view returns (uint256[2] memory) {
        return [deposits[depositOwner][address(_token0)], deposits[depositOwner][address(_token1)]];
    }
}