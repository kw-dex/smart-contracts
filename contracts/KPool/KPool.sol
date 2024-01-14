// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KRC20/IKRC20.sol";
import "contracts/KPool/IKPool.sol";
import "contracts/KWrapper.sol";

contract KPool is IKPool, Ownable {
    IKRC20 internal _token0;

    IKRC20 internal _token1;

    KWrapper internal _wrapper;

    struct Participant {
        address account;
        bool isParticipant;
    }

    mapping(address => mapping(address => uint256)) internal _deposits;

    mapping(address => uint256) internal _totalDeposits;

    mapping(address => mapping(address => uint256)) internal _rewards;

    mapping(address => uint256) internal _totalRewards;

    mapping(address => Participant) internal _participants;

    address[] internal _participantAddresses;

    uint256 internal _feePercent;

    uint256 public sharesDenominator = 1e10;

    uint256 public feeDenominator = 1e7;

    constructor (
        address token0Address,
        address token1Address,
        address poolOwner,
        address wrapperAddress,
        uint256 feePercent
    ) {
        _token0 = IKRC20(token0Address);
        _token1 = IKRC20(token1Address);
        _owner = poolOwner;
        _wrapper = KWrapper(wrapperAddress);
        _feePercent = feePercent;
    }

    // Deposit

    function depositTokens(uint256 amount0, uint256 amount1) external {
        _token0.transferFrom(msg.sender, address(this), amount0);
        _token1.transferFrom(msg.sender, address(this), amount1);

        _deposits[msg.sender][address(_token0)] += amount0;
        _deposits[msg.sender][address(_token1)] += amount1;

        _totalDeposits[address(_token0)] += amount0;
        _totalDeposits[address(_token1)] += amount1;

        addParticipant(msg.sender);

        emit Deposit(msg.sender, amount0, amount1);
    }

    // Withdraw

    function withdrawTokens(uint8 withdrawPercent) external {
        uint256[2] memory amounts = estimateWithdrawAmount(withdrawPercent, msg.sender);

        if (withdrawPercent == 100) deleteParticipant(msg.sender);

        _totalDeposits[address(_token0)] -= amounts[0];
        _totalDeposits[address(_token1)] -= amounts[1];

        _token0.transfer(msg.sender, amounts[0]);
        _token1.transfer(msg.sender, amounts[1]);

        _deposits[msg.sender][address(_token0)] -= amounts[0];
        _deposits[msg.sender][address(_token1)] -= amounts[1];

        if (_deposits[msg.sender][address(_token0)] <= 0 && _deposits[msg.sender][address(_token1)] <= 0) {
            deleteParticipant(msg.sender);
        }

        emit Withdraw(msg.sender, amounts[0], amounts[1]);
    }

    function estimateWithdrawAmount(uint8 withdrawPercent, address holder) public view returns (uint256[2] memory) {
        require(withdrawPercent > 0 && withdrawPercent <= 100, "Invalid withdraw percent");

        uint256[2] memory shares = estimateAccountShare(msg.sender);

        uint256 balance0 = getPoolTokenBalance(address(_token0));
        uint256 balance1 = getPoolTokenBalance(address(_token1));

        uint256 amount0 = (((balance0 * shares[0]) / sharesDenominator) * withdrawPercent) / 1e2;
        uint256 amount1 = (((balance1 * shares[1]) / sharesDenominator) * withdrawPercent) / 1e2;

        if (amount0 > _deposits[holder][address(_token0)]) amount0 = _deposits[holder][address(_token0)];
        if (amount1 > _deposits[holder][address(_token1)]) amount1 = _deposits[holder][address(_token1)];

        if (amount0 > getPoolTokenBalance(address(_token0))) amount0 = getPoolTokenBalance(address(_token0));
        if (amount1 > getPoolTokenBalance(address(_token1))) amount1 = getPoolTokenBalance(address(_token1));

        return [amount0, amount1];
    }

    // Exchange

    function exchangeToken(address tokenAddress, uint256 amount) external {
        uint256 feeAmount = (amount * _feePercent) / 1e7;

        uint256 tokenAmount = estimateExchangeAmount(tokenAddress, amount);

        require(tokenAmount > 0, "Invalid exchange amount");

        bool ltr = isLTR(tokenAddress);

        // Distribute fees
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            address participantAddress = _participantAddresses[i];

            if (!_participants[participantAddress].isParticipant) continue;

            uint256[2] memory shares = estimateAccountShare(participantAddress);

            uint256 rewardAmount = (feeAmount * shares[ltr ? 0 : 1]) / sharesDenominator;

            _rewards[participantAddress][tokenAddress] += rewardAmount;
        }

        if (ltr) {
            _token0.transferFrom(msg.sender, address(this), amount);

            _token1.transfer(msg.sender, tokenAmount);
        } else {
            _token1.transferFrom(msg.sender, address(this), amount);

            _token0.transfer(msg.sender, tokenAmount);
        }

        _totalRewards[tokenAddress] += feeAmount;

        emit Exchange(ltr ? address(_token0) : address(_token1), ltr ? address(_token1) : address(_token0), amount, tokenAmount);
    }

    function estimateExchangeAmount(address tokenAddress, uint256 amount) public view returns (uint256) {
        uint256 feeAmount = (amount * _feePercent) / feeDenominator;

        uint256 tokenBalance = getPoolTokenBalance(tokenAddress);

        uint256 priceImpact = estimatePriceImpact(tokenBalance, (tokenBalance - amount));

        bool ltr = isLTR(tokenAddress);

        uint256 balance0 = getPoolTokenBalance(address(_token0));
        uint256 balance1 = getPoolTokenBalance(address(_token1));

        uint256 plainBalance0 = balance0 * (10 ** _token1.decimals());
        uint256 plainBalance1 = balance1 * (10 ** _token0.decimals());

        uint256 decimalSum = 10 ** (_token1.decimals() + _token0.decimals());

        uint tokenExchange;

        if(ltr) {
            tokenExchange = ((amount - feeAmount)) * (plainBalance1 * decimalSum / plainBalance0) / (10 ** _token0.decimals());
        } else {
            tokenExchange = ((amount - feeAmount)) * (plainBalance0 * decimalSum / plainBalance1) / (10 ** _token1.decimals());
        }

        return tokenExchange * (1e6 - priceImpact) / 1e6 / (10 ** IKRC20(tokenAddress).decimals());
    }

    // Rewards

    function claimRewards() external {
        uint256[2] memory rewardsAmount = estimateRewardsAmount(msg.sender);

        _token0.transfer(msg.sender, rewardsAmount[0]);
        _token1.transfer(msg.sender, rewardsAmount[1]);

        _rewards[msg.sender][address(_token0)] -= rewardsAmount[0];
        _rewards[msg.sender][address(_token1)] -= rewardsAmount[1];

        _totalRewards[address(_token0)] -= rewardsAmount[0];
        _totalRewards[address(_token1)] -= rewardsAmount[1];

        emit ClaimRewards(msg.sender, rewardsAmount[0], rewardsAmount[1]);
    }

    function estimateRewardsAmount(address account) public view returns (uint256[2] memory) {
        return [_rewards[account][address(_token0)], _rewards[account][address(_token1)]];
    }

    function estimateOwnerRewards() public view returns (uint256[2] memory) {
        uint256 maxTransferAmount0 = getPoolTokenBalance(address(_token0)) - _totalDeposits[address(_token0)];
        uint256 maxTransferAmount1 = getPoolTokenBalance(address(_token1)) - _totalDeposits[address(_token1)];

        return [maxTransferAmount0, maxTransferAmount1];
    }

    function withdrawOwnerRewards() external onlyOwner {
        uint256 maxTransferAmount0 = getPoolTokenBalance(address(_token0)) - _totalDeposits[address(_token0)];
        uint256 maxTransferAmount1 = getPoolTokenBalance(address(_token1)) - _totalDeposits[address(_token1)];

        _token0.transfer(msg.sender, maxTransferAmount0);
        _token0.transfer(msg.sender, maxTransferAmount1);
    }

    // Private calculations

    function estimatePriceImpact(uint256 tokenBalanceBefore, uint256 tokenBalanceAfter) private pure returns (uint256) {
        uint256 priceImpact = ((tokenBalanceBefore - tokenBalanceAfter) * 1e6) / tokenBalanceBefore;
        return priceImpact;
    }

    function estimateAccountShare(address account) private view returns (uint256[2] memory) {
        uint256 accountShare0 = _totalDeposits[address(_token0)] == 0 ? 0 : (_deposits[account][address(_token0)] * sharesDenominator / _totalDeposits[address(_token0)]);
        uint256 accountShare1 = _totalDeposits[address(_token1)] == 0 ? 0 : (_deposits[account][address(_token1)] * sharesDenominator / _totalDeposits[address(_token1)]);

        if (_deposits[account][address(_token0)] > _totalDeposits[address(_token0)]) accountShare0 = sharesDenominator;
        if (_deposits[account][address(_token1)] > _totalDeposits[address(_token1)]) accountShare1 = sharesDenominator;

        return [accountShare0, accountShare1];
    }

    // Pool data view

    function token0() external view returns (address) {
        return address(_token0);
    }

    function token1() external view returns (address) {
        return address(_token1);
    }

    function fee() external view returns (uint256) {
        return _feePercent;
    }

    function isLTR(address _token0Address) public view returns (bool) {
        if (_token0Address == address(_token0)) return true;

        return false;
    }

    function getAccountData(address owner) external view returns (AccountData memory) {
        uint256[2] memory accountShares = estimateAccountShare(owner);
        uint256[2] memory accountDeposits = [
        _deposits[owner][address(_token0)],
        _deposits[owner][address(_token1)]
        ];

        uint256[2] memory accountRewards = estimateRewardsAmount(owner);

        return AccountData(accountShares, accountDeposits, accountRewards);
    }

    function participants() external view returns (uint256) {
        return _participantAddresses.length;
    }

    function totalDeposits() external view returns (uint256[2] memory) {
        return [_totalDeposits[address(_token0)], _totalDeposits[address(_token1)]];
    }

    function poolBalances() external view returns (uint256[2] memory) {
        return [_token0.balanceOf(address(this)), _token1.balanceOf(address(this))];
    }

    // Internal utils

    function deleteParticipant(address account) private {
        for (uint256 i = 0; i < _participantAddresses.length; i++) {
            if (_participantAddresses[i] == account) {
                delete _participantAddresses[i];
                _participants[account] = Participant(account, false);

                return;
            }
        }
    }

    function addParticipant(address account) private {
        if (_participants[account].isParticipant) return;

        _participantAddresses.push(account);
        _participants[account] = Participant(account, true);
    }

    function getPoolTokenBalance(address tokenAddress) private view returns (uint256) {
        IKRC20 token = IKRC20(tokenAddress);

        return token.balanceOf(address(this)) - _totalRewards[tokenAddress];
    }
}
