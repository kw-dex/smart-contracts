// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/tokens/IERC20.sol";
import "contracts/utils/Ownable.sol";

contract KERC20 is KERC20Token, Ownable {
    string _symbol;
    string _name;
    uint16 _decimals;

    uint256 _totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;

    constructor(
        string memory _tokenSymbol,
        string memory _tokenName,
        uint16 _tokenDecimals,
        address _tokenOwner
    ) {
        _symbol = _tokenSymbol;
        _name = _tokenName;
        _decimals = _tokenDecimals;
        _owner = _tokenOwner;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) external returns (bool success) {
        require(balances[msg.sender] >= tokens, "Not enough balance");

        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;

        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) external returns (bool success) {
        require(allowed[from][to] >= tokens, "Not enough allowance");
        require(balances[from] >= tokens, "Not enough balance");

        allowed[from][to] = allowed[from][to] - tokens;
        balances[from] = balances[from] - tokens;
        balances[to] = balances[to] + tokens;

        emit Transfer(from, to, tokens);
        return true;
    }

    function mint(uint256 amount) external returns (bool success) {
        require(msg.sender == _owner, "Not an owner");

        balances[msg.sender] = balances[msg.sender] + amount;
        _totalSupply = _totalSupply + amount;

        emit Mint(amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool success) {
        require(balances[msg.sender] >= amount, "Not enough balance");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[address(0)] = balances[address(0)] + amount;

        emit Burn(msg.sender, amount);
        return true;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }
}