// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KRC20/IKRC20.sol";
import "contracts/Ownable/Ownable.sol";

contract KRC20 is IKRC20, Ownable {
    string internal _symbol;
    string internal _name;
    uint16 internal _decimals;

    uint256 internal _totalSupply;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping(address => uint256)) internal _allowance;

    modifier requireBalance(uint256 balance) {
        require(_balances[msg.sender] >= balance, "Not enough balance");
        _;
    }

    constructor(
        string memory tokenSymbol,
        string memory tokenName,
        uint16 tokenDecimals,
        address owner
    ) {
        require(tokenDecimals >= 0 && tokenDecimals <= 18, "Invalid token decimals");
        _symbol = tokenSymbol;
        _name = tokenName;
        _decimals = tokenDecimals;
        _owner = owner;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply - _balances[address(0)];
    }

    function balanceOf(address tokenOwner) external view returns (uint256) {
        return _balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowance[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) external requireBalance(tokens) {
        _balances[msg.sender] = _balances[msg.sender] - tokens;
        _balances[to] = _balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint256 amount) external {
        if (amount == type(uint256).max) _allowance[msg.sender][spender] = type(uint256).max;
        else _allowance[msg.sender][spender] += amount;
    }

    function transferFrom(address from, address to, uint256 tokens) external {
        require(checkAllowance(tokens, from, to), "Not enough allowance");
        require(_balances[from] >= tokens, "Not enough balance");

        if (_allowance[from][to] < type(uint256).max) _allowance[from][to] = _allowance[from][to] - tokens;

        _balances[from] = _balances[from] - tokens;
        _balances[to] = _balances[to] + tokens;

        emit Transfer(from, to, tokens);
    }

    function mint(uint256 amount) external onlyOwner {
        _balances[msg.sender] = _balances[msg.sender] + amount;
        _totalSupply = _totalSupply + amount;

        emit Mint(amount);
    }

    function burn(uint256 amount) external requireBalance(amount) {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Burn(msg.sender, amount);
    }

    function decreaseAllowance(address spender, uint256 amount) external {
        if (amount > _allowance[msg.sender][spender]) _allowance[msg.sender][spender] = 0;
        else _allowance[msg.sender][spender] -= amount;
    }

    function transferData(address to, uint256 tokens, bytes[] calldata callData) external requireBalance(tokens) {
        _balances[msg.sender] -= tokens;
        _balances[to] += tokens;

        emit Transfer(msg.sender, to, tokens);

        for (uint256 i = 0; i < callData.length; i++) {
            bytes calldata data = callData[i];

            (bool success, bytes memory response) = to.call(data);

            if (!success) revert ExecutionError(to, callData, response);
        }
    }

    function checkAllowance(uint256 amount, address tokenOwner, address spender) private view returns (bool) {
        return _allowance[tokenOwner][spender] >= amount;
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
