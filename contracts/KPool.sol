// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/utils/Ownable.sol";
import "contracts/tokens/KERC20.sol";

contract KPool is Ownable {
    KERC20 _token0;
    KERC20 _token1;

    mapping (address => mapping(address => uint256)) deposits;

    mapping (address => uint256) _totalDeposits;

    mapping (address => mapping(address => uint256)) rewards;

    mapping (address => uint256) _totalRewards;

    struct Participant {
        address account;
        bool isParticipant;
    }

    mapping (address => Participant) participants;
    address[] _participantAddresses;
    uint256 feePercent;

    event Deposit(address indexed from, address indexed token, uint256 amount);

    event Withdraw(address indexed to, address indexed token, uint256 amount);

    event Exchange(address indexed fromToken, address indexed toToken, uint256 amountSpend, uint256 amountReceived);

    event RewardsWithdrawn(address indexed to, uint256 token0, uint256 token1);

    uint256 _sharesDenominator = 1e10;

    uint256 _feeDonominator = 1e5;

    constructor (
        address _poolToken0Address,
        address _poolToken1Address,
        address _poolOwner,
        uint256 _feePercent
    ) {
        _token0 = KERC20(_poolToken0Address);
        _token1 = KERC20(_poolToken1Address);
        _owner = _poolOwner;
        feePercent = _feePercent;
    }

    function depositToken(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Invalid amounts");

        KERC20 token = KERC20(tokenAddress);

        token.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender][tokenAddress] += amount;
        _totalDeposits[tokenAddress] += amount;

        addParticipant(msg.sender);

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdrawToken(address tokenAddress, uint8 withdrawPercent) public {
        KERC20 token = KERC20(tokenAddress);

        bool ltr = isLTR(tokenAddress);
        uint256 amount = estimateWithdrawAmount(withdrawPercent)[ltr ? 0 : 1];

        require(deposits[msg.sender][tokenAddress] >= amount, "Not enough deposit");
        require(getPoolTokenBalance(tokenAddress) >= amount, "Not enough pool balance");

        _totalDeposits[tokenAddress] -= amount;

        token.transfer(msg.sender, amount);

        deposits[msg.sender][tokenAddress] -= amount;

        if (deposits[msg.sender][address(_token0)] <= 0 && deposits[msg.sender][address(_token1)] <= 0) {
            deleteParticipant(msg.sender);
        }

        emit Withdraw(msg.sender, tokenAddress, amount);
    }

    function estimateWithdrawAmount(uint8 withdrawPercent) public view returns (uint256[2] memory) {
        require(withdrawPercent > 0 && withdrawPercent <= 100, "Invalid withdraw percent");

        uint256[2] memory shares = estimateAccountShare(msg.sender);

        uint256 balance0 = getPoolTokenBalance(address(_token0));
        uint256 balance1 = getPoolTokenBalance(address(_token1));

        uint256 amount0 = (((balance0 * shares[0]) / _sharesDenominator) * withdrawPercent) / 1e2;
        uint256 amount1 = (((balance1 * shares[1]) / _sharesDenominator) * withdrawPercent) / 1e2;

        return [amount0, amount1];
    }

    function exchangeToken(address tokenAddress, uint256 amount) public {
        uint256 feeAmount = (amount * feePercent) / 1e5;

        uint256 tokenAmount = estimateExchangeAmount(tokenAddress, amount);

        require(tokenAmount > 0, "Invalid exchange amount");

        bool ltr = isLTR(tokenAddress);

        if (ltr) {
            _token0.transferFrom(msg.sender, address(this), amount);

            _token1.transfer(msg.sender, tokenAmount);
        } else {
            _token1.transferFrom(msg.sender, address(this), amount);

            _token0.transfer(msg.sender, tokenAmount);
        }

        _totalRewards[tokenAddress] += feeAmount;

        emit Exchange(ltr ? address(_token0) : address(_token1), ltr ? address(_token1) : address(_token0), amount, tokenAmount);

        // Distribute fees
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            address participantAddress = _participantAddresses[i];

            if (!participants[participantAddress].isParticipant) continue;

            uint256[2] memory shares = estimateAccountShare(participantAddress);

            uint256 rewardAmount = (feeAmount * shares[ltr ? 0 : 1]) / _sharesDenominator;

            rewards[participantAddress][tokenAddress] += rewardAmount;
        }
    }

    function withdrawRewards () external {
        uint256[2] memory rewardsAmount = estimateRewardsAmount(msg.sender);

        _token0.transfer(msg.sender, rewardsAmount[0]);
        _token1.transfer(msg.sender, rewardsAmount[1]);

        rewards[msg.sender][address(_token0)] -= rewardsAmount[0];
        rewards[msg.sender][address(_token1)] -= rewardsAmount[1];

        _totalRewards[address(_token0)] -= rewardsAmount[0];
        _totalRewards[address(_token1)] -= rewardsAmount[1];

        emit RewardsWithdrawn(msg.sender, rewardsAmount[0], rewardsAmount[1]);
    }

    function isLTR(address _token0Address) public view returns (bool) {
        if (_token0Address == address(_token0)) return true;

        return false;
    }

    function estimateExchangeAmount(address tokenAddress, uint256 amount) public view returns (uint) {
        uint256 feeAmount = (amount * feePercent) / _feeDonominator;

        uint256 tokenBalance = getPoolTokenBalance(tokenAddress);

        uint256 priceImpact = calculatePriceImpact(tokenBalance, (tokenBalance - amount));
    
        bool ltr = isLTR(tokenAddress);

        uint256 balance0 = getPoolTokenBalance(address(_token0));
        uint256 balance1 = getPoolTokenBalance(address(_token1));

        uint token1Exchange = ((amount - feeAmount) * 1e3) * (balance1 * 1e3 / balance0);
        uint token0Exchange = ((amount - feeAmount) * 1e3) * (balance0 * 1e3 / balance1);

        token1Exchange = token1Exchange * (1e6 - priceImpact) / 1e6;
        token0Exchange = token0Exchange * (1e6 - priceImpact) / 1e6;

        return (ltr ? token1Exchange : token0Exchange) / 1e6;
    }

    function calculatePriceImpact(uint256 tokenBalanceBefore, uint256 tokenBalanceAfter) private pure returns (uint256) {
        uint256 priceImpact = ((tokenBalanceBefore - tokenBalanceAfter) * 1e6) / tokenBalanceBefore;
        return priceImpact;
    }

    function estimateAccountShare(address accountAddress) public view returns (uint256[2] memory) {
        uint256 accountShare0 =  _totalDeposits[address(_token0)] == 0 ? 0 : (deposits[accountAddress][address(_token0)] * _sharesDenominator / _totalDeposits[address(_token0)]);
        uint256 accountShare1 = _totalDeposits[address(_token1)] == 0 ? 0 : (deposits[accountAddress][address(_token1)] * _sharesDenominator / _totalDeposits[address(_token1)]);

        if (deposits[accountAddress][address(_token0)] > _totalDeposits[address(_token0)]) accountShare0 = _sharesDenominator;
        if (deposits[accountAddress][address(_token1)] > _totalDeposits[address(_token1)]) accountShare1 = _sharesDenominator;

        return [accountShare0, accountShare1];
    }

    function estimateRewardsAmount(address participantAddress) public view returns (uint256[2] memory) {
        return [rewards[participantAddress][address(_token0)], rewards[participantAddress][address(_token1)]];
    }

    function getDepositAmounts(address depositOwner) external view returns (uint256[2] memory) {
        return [deposits[depositOwner][address(_token0)], deposits[depositOwner][address(_token1)]];
    }

    function deleteParticipant(address account) private {
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            if (_participantAddresses[i] == account) {
                delete _participantAddresses[i];
                participants[account] = Participant(account, false);

                return;
            }
        }
    }

    function addParticipant(address account) private {
        if (participants[account].isParticipant) return;

        _participantAddresses.push(account);
        participants[account] = Participant(account, true);
    }

    function getPoolTokenBalance(address tokenAddress) public view returns (uint256) {
        KERC20 token = KERC20(tokenAddress);

        return token.balanceOf(address(this)) - _totalRewards[tokenAddress];
    }

    function token0() external view returns (address) {
        return address(_token0);
    }

    function token1() external view returns (address) {
        return address(_token1);
    }

    function fee() external view returns (uint256) {
        return feePercent;
    }
}