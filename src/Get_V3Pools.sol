// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Get all the possible V3 pools based on token pair and all fee tiers */

interface IV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

interface IV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address);
}

contract GetV3Pools {
    struct V3PoolInfo {
        address addr;
        address token0;
        address token1;
        uint24 fee;
    }

    uint24[] feeTiers = [100, 500, 3000, 10000];

    V3PoolInfo[] public pools;

    constructor(address factory, address tokenA, address tokenB) {
        for (uint256 i = 0; i < feeTiers.length; i++) {
            address poolAddr = IV3Factory(factory).getPool(
                tokenA,
                tokenB,
                feeTiers[i]
            );
            if (poolAddr != address(0)) {
                IV3Pool pool = IV3Pool(poolAddr);
                V3PoolInfo memory v3Pool = V3PoolInfo({
                    addr: poolAddr,
                    token0: pool.token0(),
                    token1: pool.token1(),
                    fee: pool.fee()
                });
                pools.push(v3Pool);
            }
        }
        bytes memory abiEncodedData = abi.encode(pools);

        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}
