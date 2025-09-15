// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Query the reserves of multiple V2 pools */

interface V2Pool {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract V2PoolState {
    
    struct PoolState {
        address pool;
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }
    
    PoolState[] public reserves;

    constructor(address[] memory pools) {
        for (uint256 i = 0; i < pools.length; i++) {
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = V2Pool(pools[i]).getReserves();
            PoolState memory poolReserves = PoolState({
                pool: pools[i],
                reserve0: reserve0,
                reserve1: reserve1,
                blockTimestampLast: blockTimestampLast
            });
            reserves.push(poolReserves);
        }
        
        bytes memory abiEncodedData = abi.encode(reserves);
        
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}