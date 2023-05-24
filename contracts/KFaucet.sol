// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/utils/Ownable.sol";
import "contracts/tokens/KERC20.sol";

contract KFaucet is Ownable {
    uint256 _limitation = 5;
    uint256 _amount = 1;

    constructor() {
        _owner = msg.sender;
    }

    function requestToken(address _tokenAddress) external returns (bool) {
        KERC20 token = KERC20(_tokenAddress);

        uint256 _tokenLimitation = this.tokenLimitation(_tokenAddress);
        uint256 _tokenSendAmount = _amount * (10 ** token.decimals());

        require(token.balanceOf(msg.sender) < _tokenLimitation, "Maximum amount received");

        if (token.owner() == address(this)) {
            token.mint(_tokenSendAmount);
            token.transfer(msg.sender, _tokenSendAmount);

            return true;
        }

        require(token.balanceOf(address(this)) >= _tokenSendAmount, "Not enough faucet balance");

        token.transfer(msg.sender, _tokenSendAmount);

        return true;
    }

    function tokenLimitation(address _tokenAddress) external view returns (uint256) {
        KERC20 token = KERC20(_tokenAddress);

        return _limitation * (10 ** token.decimals());
    }

    function transferTokenOwnership(address _tokenAddress) external returns (bool) {
        require(msg.sender == _owner, "Not an faucet owner");
        KERC20 token = KERC20(_tokenAddress);

        token.transferOwnership(_owner);

        return true;
    }
}