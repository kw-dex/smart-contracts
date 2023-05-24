// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KPool.sol";
import "contracts/tokens/KERC20.sol";

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

    event MultiSwapPartial(
        address indexed from,
        address indexed to,
        address latestTo,
        uint256 spend,
        uint256 received,
        address indexed account
    );

    event MultiSwapError(
        address indexed from,
        address indexed to,
        uint256 spend,
        address indexed account
    );

    function estimateSwapFees(RouteStep[] memory steps) external view returns (uint256) {
        uint256 totalFee;

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            KPool pool = KPool(stepData.pool);
            totalFee += pool.fee();
        }

        return totalFee;
    }

    function multiSwap(uint256 amount, RouteStep[] memory steps, address receiveTokenAddress) external {
        KERC20 initialSpendToken = KERC20(steps[0].spendToken);

        initialSpendToken.transferFrom(msg.sender, address(this), amount);

        for (uint256 i = 0; i < steps.length; i++) {
            RouteStep memory stepData = steps[i];

            KPool pool = KPool(stepData.pool);
            KERC20 spendToken = KERC20(stepData.spendToken);

            spendToken.approve(stepData.pool, spendToken.balanceOf(address(this)));

            try pool.exchangeToken(stepData.spendToken, spendToken.balanceOf(address(this))) {
                continue;
            } catch {
                if (i == 0) {
                    emit MultiSwapError(steps[0].spendToken, receiveTokenAddress, amount, msg.sender);

                    return;
                }

                address latestTokenAddress = pool.isLTR(stepData.spendToken) ? pool.token1() : pool.token0();

                KERC20 latestReceivedToken = KERC20(latestTokenAddress);

                uint256 latestAmount = latestReceivedToken.balanceOf(address(this));
        
                emit MultiSwapPartial(
                    steps[0].spendToken,
                    receiveTokenAddress,
                    latestTokenAddress,
                    amount, 
                    latestAmount,
                    msg.sender
                );

                return;
            }
        }

        KERC20 receivedToken = KERC20(receiveTokenAddress);

        uint256 receivedAmount = receivedToken.balanceOf(address(this));

        receivedToken.transfer(msg.sender, receivedAmount);

        emit MultiSwapSuccess(steps[0].spendToken, receiveTokenAddress, amount, receivedAmount, msg.sender);
    }
}