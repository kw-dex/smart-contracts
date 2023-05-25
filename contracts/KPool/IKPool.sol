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

    function depositToken(address tokenAddress, uint256 amount) external;

    function withdrawToken(address tokenAddress, uint8 withdrawPercent) external;

    function exchangeToken(address tokenAddress, uint256 amount) external;

    function withdrawRewards () external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint256);

    function getAccountData() external view returns (AccountData memory);
}