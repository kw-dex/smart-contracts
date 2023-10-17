// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/Ownable/Ownable.sol";
import "contracts/KPool/IKPool.sol";
import "contracts/KPool/KPool.sol";

contract KPoolFactory is Ownable {
    struct DeployedPoolData {
        address token0;
        address token1;
        address poolAddress;
        bool deployed;
    }

    mapping (bytes32 => DeployedPoolData) private _deployedPools;
    bytes32[] private _deployedPoolKeys;

    address private _wrapperAddress;

    event PoolDeployed(address indexed poolAddress, address indexed owner);

    constructor(address wrapperAddress) {
        _owner = msg.sender;
        _wrapperAddress = wrapperAddress;
    }

    function deployPool(
        address _token0Address,
        address _token1Address,
        uint256 _feePercent
    ) external returns (address) {
        DeployedPoolData memory existingPool = this.getPool(_token0Address, _token1Address, _feePercent);

        if (existingPool.deployed) revert("pool exist");

        IKPool pool = new KPool(_token0Address, _token1Address, msg.sender, _wrapperAddress, _feePercent);

        address _rightToken0Address = _token0Address > _token1Address ? _token0Address : _token1Address;
        address _rightToken1Address = _token0Address > _token1Address ? _token1Address : _token0Address;

        bytes32 poolKey = keccak256(abi.encodePacked(_token0Address, _token1Address, _feePercent));

        _deployedPools[poolKey] = DeployedPoolData(
            _rightToken0Address,
            _rightToken1Address,
            address(pool),
            true
        );

        _deployedPoolKeys.push(poolKey);

        emit PoolDeployed(address(pool), msg.sender);
        return address(pool);
    }

    function getPool(address _token0, address _token1, uint256 _feePercent) external view returns (DeployedPoolData memory) {
        bytes32 poolKey = keccak256(abi.encodePacked(_token0, _token1, _feePercent));
        bytes32 reversePoolKey = keccak256(abi.encodePacked(_token1, _token0, _feePercent));

        if (_deployedPools[poolKey].deployed) return _deployedPools[poolKey];

        if (_deployedPools[reversePoolKey].deployed) return _deployedPools[reversePoolKey];

        return DeployedPoolData(_token0, _token1, address(0), false);
    }

    function getDeployedPools() public view returns (DeployedPoolData[] memory) {
        DeployedPoolData[] memory pools = new DeployedPoolData[](_deployedPoolKeys.length);

        for (uint i = 0; i < _deployedPoolKeys.length; i++) {
            pools[i] = _deployedPools[_deployedPoolKeys[i]];
        }

        return pools;
    }
}
