// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KRC20/KRC20.sol";

contract KFaucet is Ownable {
    uint256 internal _limitation = 5;
    uint256 internal _amount = 1;

    constructor() {
        _owner = msg.sender;
    }

    function requestToken(address tokenAddress) external {
        IKRC20 token = IKRC20(tokenAddress);

        uint256 limitation = this.tokenLimitation(tokenAddress);
        uint256 sendAmount = _amount * (10 ** token.decimals());

        require(token.balanceOf(msg.sender) < limitation, "Maximum amount received");

        if (token.owner() == address(this)) {
            token.mint(sendAmount);
            token.transfer(msg.sender, sendAmount);

            return;
        }

        require(token.balanceOf(address(this)) >= sendAmount, "Not enough faucet balance");

        token.transfer(msg.sender, sendAmount);
    }

    function tokenLimitation(address _tokenAddress) external view returns (uint256) {
        IKRC20 token = IKRC20(_tokenAddress);
        return _limitation * (10 ** token.decimals());
    }

    function transferTokenOwnership(address _tokenAddress) external onlyOwner {
        IKRC20 token = IKRC20(_tokenAddress);

        token.transferOwnership(_owner);
    }
}