// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KRC20/IKRC20.sol";
import "contracts/Math.sol";
import "./KRC20/KRC20.sol";

contract KPool {
    uint24 public fee;
    address public tokenA;
    address public tokenB;

    uint256 public totalSupply;

    mapping(address => uint256) public liquidityBalance;

    event Swap(address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);

    event AddLiquidity(uint256 amountA, uint256 amountB, uint256 liquidity);

    event RemoveLiquidity(uint256 liquidity, uint256 amountA, uint256 amountB);

    constructor (
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        fee = _fee;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "");

        IKRC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IKRC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            liquidity = Math.min(amountA * totalSupply / IKRC20(tokenA).balanceOf(address(this)), amountB * totalSupply / IKRC20(tokenB).balanceOf(address(this)));
        }

        totalSupply += liquidity;
        liquidityBalance[msg.sender] += liquidity;

        emit AddLiquidity(amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external {
        require(liquidity > 0, "Invalid amount");
        require(liquidityBalance[msg.sender] >= liquidity, "Insufficient liquidity");

        uint256[2] memory amountsOut = estimateRemoveAmount(liquidity);

        totalSupply -= liquidity;
        liquidityBalance[msg.sender] -= liquidity;

        IKRC20(tokenA).transfer(msg.sender, amountsOut[0]);
        IKRC20(tokenB).transfer(msg.sender, amountsOut[1]);

        emit RemoveLiquidity(liquidity, amountsOut[0], amountsOut[1]);
    }

    function swap(address fromToken, uint256 amountIn) external {
        address toToken = fromToken == tokenA ? tokenB : tokenA;

        uint256 amountOut = estimateSwapAmount(fromToken, amountIn);

        IKRC20(fromToken).transferFrom(msg.sender, address(this), amountIn);
        IKRC20(toToken).transfer(msg.sender, amountOut);

        emit Swap(fromToken, toToken, amountIn, amountOut);
    }

    function estimateRemoveAmount(uint256 liquidity) public view returns (uint256[2] memory) {
        uint256 amountA = liquidity * IKRC20(tokenA).balanceOf(address(this)) / totalSupply;
        uint256 amountB = liquidity * IKRC20(tokenB).balanceOf(address(this)) / totalSupply;

        return [amountA, amountB];
    }

    function estimateSwapAmount(address fromToken, uint256 amountIn) public view returns (uint256 amountOut) {
        require(fromToken == tokenA || fromToken == tokenB, "Invalid token");

        uint256 balance0 = IKRC20(tokenA).balanceOf(address(this));
        uint256 balance1 = IKRC20(tokenB).balanceOf(address(this));

        if (fromToken == tokenA) {
            amountOut = getAmountOut(amountIn, balance0, balance1);
        } else {
            amountOut = getAmountOut(amountIn, balance1, balance0);
        }

        return amountOut;
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private view returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * (1e4 - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1e4 + amountInWithFee;

        return numerator / denominator;
    }

    function balanceOf(address holder) public view returns (uint256) {
        return liquidityBalance[holder];
    }
}
