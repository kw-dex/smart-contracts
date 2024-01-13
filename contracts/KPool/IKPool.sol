// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KPool/IKPoolEvents.sol";
import "contracts/Ownable/IOwnable.sol";

interface IKPool is IKPoolEvents, IOwnable {
    struct AccountData {
        uint256[2] shares;
        uint256[2] deposits;
        uint256[2] rewards;
    }

    function depositTokens(uint256 amount0, uint256 amount1) external;

    function withdrawTokens(uint8 withdrawPercent) external;

    function estimateWithdrawAmount(uint8 withdrawPercent) external view returns (uint256[2] memory);

    function exchangeToken(address tokenAddress, uint256 amount) external;

    function estimateExchangeAmount(address tokenAddress, uint256 amount) external view returns (uint256);

    function claimRewards () external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint256);

    function getAccountData() external view returns (AccountData memory);
}
