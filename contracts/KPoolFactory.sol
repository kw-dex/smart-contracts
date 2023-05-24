// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/utils/Ownable.sol";
import "contracts/tokens/KERC20.sol";
import "contracts/KPool.sol";

contract KPoolFactory is Ownable {
    struct DeployedPoolData {
        address token0;
        address token1;
        address poolAddress;
        bool deployed;
    }

    mapping (bytes32 => DeployedPoolData) _deployedPools;

    event PoolDeployed(address indexed poolAddress, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    function deployPool(address _token0Address, address _token1Address, uint8 _feePercent) external returns (address) {
        DeployedPoolData memory existingPool = this.resolvePoolAddress(_token0Address, _token1Address);

        if (existingPool.deployed) return existingPool.poolAddress;

        KPool pool = new KPool(_token0Address, _token1Address, msg.sender, _feePercent);
        _deployedPools[keccak256(abi.encodePacked(_token0Address, _token1Address))] = DeployedPoolData(
            _token0Address,
            _token1Address,
            address(pool),
            true
        );

        emit PoolDeployed(address(pool), msg.sender);
        return address(pool);
    }

    function resolvePoolAddress(address _token0, address _token1) external view returns (DeployedPoolData memory) {
        bytes32 poolKey = keccak256(abi.encodePacked(_token0, _token1));
        bytes32 reversePoolKey = keccak256(abi.encodePacked(_token1, _token0));

        if (_deployedPools[poolKey].deployed) return _deployedPools[poolKey];

        if (_deployedPools[reversePoolKey].deployed) return _deployedPools[reversePoolKey];

        return DeployedPoolData(_token0, _token1, address(0), false);
    }
}