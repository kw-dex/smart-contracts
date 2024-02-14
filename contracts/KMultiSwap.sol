// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KPool.sol";
import "contracts/KRC20/IKRC20.sol";
import "./KWrapper.sol";

contract KMultiSwap {
    address private _wrapperAddress;

    constructor(address wrapperAddress) {
        _wrapperAddress = wrapperAddress;
    }

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

    receive() external payable {}

    function estimateSwapFees(RouteStep[] memory steps) external view returns (uint256) {
        uint256 totalFee;

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            KPool pool = KPool(stepData.pool);
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

            prevReceiveAmount = pool.estimateSwapAmount(stepData.spendToken, prevReceiveAmount);

            receiveAmount += prevReceiveAmount;
        }

        return receiveAmount;
    }

    function getReceiveToken(RouteStep[] memory steps) private view returns (address) {
        RouteStep memory lastStep = steps[steps.length - 1];

        KPool lastPool = KPool(lastStep.pool);

        if (lastPool.tokenA() == lastStep.spendToken) return lastPool.tokenB();
        else return lastPool.tokenA();
    }

    function multiSwap(uint256 amount, RouteStep[] memory steps, bool receiveNative) external payable {
        KWrapper wrapper = KWrapper(_wrapperAddress);

        if (msg.value > 0) {
            wrapper.wrap{ value: msg.value }();
        }

        if (steps[0].spendToken != wrapper.token() || msg.value != amount) {
            IKRC20 initialSpendToken = IKRC20(steps[0].spendToken);
            initialSpendToken.transferFrom(msg.sender, address(this), amount);
        }

        address receiveTokenAddress = getReceiveToken(steps);

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            KPool pool = KPool(stepData.pool);
            IKRC20 spendToken = IKRC20(stepData.spendToken);

            spendToken.approve(stepData.pool, spendToken.balanceOf(address(this)));

            try pool.swap(stepData.spendToken, spendToken.balanceOf(address(this))) {
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

        if (receiveNative && address(receivedToken) == wrapper.token()) {
            receivedToken.approve(address(wrapper), receivedAmount);
            wrapper.unwrap(receivedAmount);
            payable(msg.sender).transfer(receivedAmount);
        } else {
            receivedToken.transfer(msg.sender, receivedAmount);
        }

        emit MultiSwapSuccess(steps[0].spendToken, receiveTokenAddress, amount, receivedAmount, msg.sender);
    }
}
