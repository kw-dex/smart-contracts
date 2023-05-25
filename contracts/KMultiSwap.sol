// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KPool/KPool.sol";
import "contracts/KRC20/IKRC20.sol";

contract KMultiSwap {
    constructor() {}

    struct RouteStep {
        address spendToken;
        address pool;
    }

    event MultiSwapSuccess(
        address indexed from,
        address indexed to,
        uint256 spend,
        uint256 received,
        address indexed account
    );

    error MultiSwapError(
        address from,
        address to,
        address pool,
        uint256 spendAmount,
        bytes reason
    );

    function estimateSwapFees(RouteStep[] memory steps) external view returns (uint256) {
        uint256 totalFee;

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            IKPool pool = IKPool(stepData.pool);
            totalFee += pool.fee();
        }

        return totalFee;
    }

    function estimateReceiveAmount(uint256 amount, RouteStep[] memory steps) external view returns (uint256) {
        uint256 receiveAmount;

        uint256 prevReceiveAmount = amount;

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            KPool pool = KPool(stepData.pool);

            prevReceiveAmount = pool.estimateExchangeAmount(stepData.spendToken, prevReceiveAmount);

            receiveAmount += prevReceiveAmount;
        }

        return receiveAmount;
    }

    function getReceiveToken(RouteStep[] memory steps) private view returns (address) {
        RouteStep memory lastStep = steps[steps.length - 1];

        IKPool lastPool = IKPool(lastStep.pool);

        if (lastPool.token0() == lastStep.spendToken) return lastPool.token1();
        else return lastPool.token0();
    }

    function multiSwap(uint256 amount, RouteStep[] memory steps) external {
        IKRC20 initialSpendToken = IKRC20(steps[0].spendToken);

        initialSpendToken.transferFrom(msg.sender, address(this), amount);

        address receiveTokenAddress = getReceiveToken(steps);

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            IKPool pool = IKPool(stepData.pool);
            IKRC20 spendToken = IKRC20(stepData.spendToken);

            spendToken.approve(stepData.pool, spendToken.balanceOf(address(this)));

            try pool.exchangeToken(stepData.spendToken, spendToken.balanceOf(address(this))) {
                continue;
            } catch (bytes memory reason) {
                revert MultiSwapError(
                    steps[0].spendToken,
                    receiveTokenAddress,
                    stepData.pool,
                    amount,
                    reason
                );
            }
        }

        IKRC20 receivedToken = IKRC20(receiveTokenAddress);

        uint256 receivedAmount = receivedToken.balanceOf(address(this));

        receivedToken.transfer(msg.sender, receivedAmount);

        emit MultiSwapSuccess(steps[0].spendToken, receiveTokenAddress, amount, receivedAmount, msg.sender);
    }
}