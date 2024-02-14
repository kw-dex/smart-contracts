// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KPool.sol";

contract KPoolFactory {
    struct DeployedPoolData {
        address tokenA;
        address tokenB;
        address poolAddress;
        uint256 fee;
        bool deployed;
    }

    mapping(bytes32 => DeployedPoolData) private _deployedPools;
    bytes32[] private _deployedPoolKeys;

    event PoolDeployed(address indexed poolAddress, address indexed owner);

    function deployPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address) {
        address _tokenA = tokenB > tokenA ? tokenA : tokenB;
        address _tokenB = tokenB > tokenA ? tokenB : tokenA;

        DeployedPoolData memory existingPool = getPool(_tokenA, _tokenB, fee);

        if (existingPool.deployed) revert("pool exist");

        KPool pool = new KPool(_tokenA, _tokenB, fee);

        bytes32 poolKey = keccak256(abi.encodePacked(_tokenA, _tokenB, fee));

        _deployedPools[poolKey] = DeployedPoolData(
            _tokenA,
            _tokenB,
            address(pool),
            fee,
            true
        );

        _deployedPoolKeys.push(poolKey);

        emit PoolDeployed(address(pool), msg.sender);
        return address(pool);
    }

    function getPool(address tokenA, address tokenB, uint256 fee) public view returns (DeployedPoolData memory) {
        bytes32 poolKey = keccak256(abi.encodePacked(tokenA, tokenB, fee));

        if (_deployedPools[poolKey].deployed) return _deployedPools[poolKey];

        return DeployedPoolData(tokenA, tokenB, address(0), fee, false);
    }

    function getDeployedPools() public view returns (DeployedPoolData[] memory) {
        DeployedPoolData[] memory pools = new DeployedPoolData[](_deployedPoolKeys.length);

        for (uint i = 0; i < _deployedPoolKeys.length; i++) {
            pools[i] = _deployedPools[_deployedPoolKeys[i]];
        }

        return pools;
    }
}
