//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @dev Query the pool state of multiple V3 pools */

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function liquidity() external view returns (uint128);
    function tickBitmap(int16 wordPos) external view returns (uint256);
    function feeGrowthGlobal0X128() external view returns (uint256);
    function feeGrowthGlobal1X128() external view returns (uint256);
    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract V3PoolState {
    struct V3Pool {
        address pool;
        address token0;
        address token1;
        int24 tickSpacing;
    }

    struct V3PoolData {
        address pool;
        uint256 token0Balance;
        uint256 token1Balance;
        uint256 feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256 tickBitmap;
        int16 wordPos;
        int128 liquidityNet;
        uint128 liquidityGross;
        bool initialized;
    }

    V3PoolData[] public allPoolData;

        constructor(V3Pool[] memory pools) {
        for (uint256 i = 0; i < pools.length; i++) {
            allPoolData.push(getPoolData(pools[i]));
        }

        // Return encoded data
        bytes memory abiEncodedData = abi.encode(allPoolData);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }

    function getPoolData(
        V3Pool memory _pool
    ) internal view returns (V3PoolData memory) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool.pool);

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        (int16 wordPos, ) = position(tick / _pool.tickSpacing);
        (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            ,
            ,
            ,
            bool initialized
        ) = pool.ticks(tick);

        return
            V3PoolData(
                _pool.pool,
                ERC20(_pool.token0).balanceOf(_pool.pool),
                ERC20(_pool.token1).balanceOf(_pool.pool),
                pool.feeGrowthGlobal0X128(),
                pool.feeGrowthGlobal1X128(),
                feeGrowthOutside0X128,
                feeGrowthOutside1X128,
                pool.liquidity(),
                sqrtPriceX96,
                tick,
                pool.tickBitmap(wordPos),
                wordPos,
                liquidityNet,
                liquidityGross,
                initialized
            );
    }

    function position(
        int24 tick
    ) internal pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick) & 0xFF);
    }
}
