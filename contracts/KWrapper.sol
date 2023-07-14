// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KRC20/IKRC20.sol";

contract KWrapper is Ownable {
    IKRC20 internal _wrappedToken;

    event Wrap(address indexed sender, uint256 amount);

    constructor(address wrappedTokenAddress) {
        _wrappedToken = IKRC20(wrappedTokenAddress);
    }

    function wrap() external payable {
        require(msg.value > 0, "Invalid wrap amount");

        _wrappedToken.mint(msg.value);
        _wrappedToken.transfer(msg.sender, msg.value);

        emit Wrap(msg.sender, msg.value);
    }

    function unwrap(uint256 amount) external {
        require(amount > 0, "Invalid unwrap amount");

        _wrappedToken.transferFrom(msg.sender, address(this), amount);
        _wrappedToken.burn(amount);

        payable(msg.sender).transfer(amount);
    }

    function transferTokenOwnership(address to) external onlyOwner {
        _wrappedToken.transferOwnership(to);
    }

    function token() external view returns (address) {
        return address(_wrappedToken);
    }
}