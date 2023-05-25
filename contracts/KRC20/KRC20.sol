// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/KRC20/IKRC20.sol";
import "contracts/Ownable/Ownable.sol";

contract KRC20 is IKRC20, Ownable {
    string _symbol;
    string _name;
    uint16 _decimals;

    uint256 _totalSupply;

    mapping (address => uint256) balances;

    mapping (address => mapping(address => uint256)) _allowance;
    mapping (address => mapping(address => bool)) _unlimitedAllowance;

    modifier requireBalance(uint256 balance) {
        require(balances[msg.sender] >= balance, "Not enough balance");

        _;
    }

    constructor(
        string memory _tokenSymbol,
        string memory _tokenName,
        uint16 _tokenDecimals,
        address _tokenOwner
    ) {
        require(_tokenDecimals >= 0 && _tokenDecimals <= 18, "Invalid token decimals");
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
        if (_unlimitedAllowance[tokenOwner][spender]) return 2**256 - 1;

        return _allowance[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens) external requireBalance(tokens) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint256 tokens) external {
        _allowance[msg.sender][spender] += tokens;
    }

    function approveUnlimited(address spender) external {
        _unlimitedAllowance[msg.sender][spender] = true;
    }

    function transferFrom(address from, address to, uint256 tokens) external {
        require(checkAllowance(tokens, from, to), "Not enough allowance");
        require(balances[from] >= tokens, "Not enough balance");

        _allowance[from][to] = _allowance[from][to] - tokens;
        balances[from] = balances[from] - tokens;
        balances[to] = balances[to] + tokens;

        emit Transfer(from, to, tokens);
    }

    function mint(uint256 amount) external onlyOwner {
        balances[msg.sender] = balances[msg.sender] + amount;
        _totalSupply = _totalSupply + amount;

        emit Mint(amount);
    }

    function burn(uint256 amount) external requireBalance(amount) {
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[address(0)] = balances[address(0)] + amount;

        emit Burn(msg.sender, amount);
    }

    function revokeApproval(address spender) external {
        _allowance[msg.sender][spender] = 0;
        _unlimitedAllowance[msg.sender][spender] = false;
    }

    function transferCallData(address to, uint256 tokens, bytes[] calldata callData) external requireBalance(tokens) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;

        emit Transfer(msg.sender, to, tokens);

        for (uint256 i = 0; i < callData.length; i++) {
            bytes calldata data = callData[i];

            (bool success, bytes memory response) = to.call(data);

            if (!success) revert ExecutionError(to, callData, response);
        }
    }

    function checkAllowance(uint256 amount, address tokenOwner, address spender) private view returns (bool) {
        if (_unlimitedAllowance[tokenOwner][spender]) return true;

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