//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @dev Query the state of multiple V4 pools */

interface IStateView {
    function getSlot0(
        bytes32 poolId
    )
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint24 protocolFee,
            uint24 lpFee
        );

    function getTickBitmap(
        bytes32 poolId,
        int16 tick
    ) external view returns (uint256 tickBitmap);

    function getFeeGrowthGlobals(
        bytes32 poolId
    )
        external
        view
        returns (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1);

    function getTickFeeGrowthOutside(
        bytes32 poolId,
        int24 tick
    )
        external
        view
        returns (
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );

    function getTickLiquidity(
        bytes32 poolId,
        int24 tick
    ) external view returns (uint128 liquidityGross, int128 liquidityNet);

    function getLiquidity(
        bytes32 poolId
    ) external view returns (uint128 liquidity);
}

contract V4PoolState {
    struct Pool {
        bytes32 pool;
        int24 tickSpacing;
    }

    struct PoolData {
        bytes32 pool;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256 tickBitmap;
        int16 wordPos;
        int128 liquidityNet;
        uint128 liquidityGross;
    }

    PoolData[] public allPoolData;

    constructor(Pool[] memory pools, address stateView) {
        IStateView stateViewContract = IStateView(stateView);

        for (uint256 i = 0; i < pools.length; i++) {
            (uint160 sqrtPriceX96, int24 tick, , ) = stateViewContract.getSlot0(
                pools[i].pool
            );

            (int16 wordPos, ) = position(tick / pools[i].tickSpacing);
            uint256 tickBitmap = stateViewContract.getTickBitmap(
                pools[i].pool,
                wordPos
            );

            uint128 liquidity = stateViewContract.getLiquidity(pools[i].pool);

            (uint128 liquidityGross, int128 liquidityNet) = stateViewContract
                .getTickLiquidity(pools[i].pool, tick);

            (
                uint256 feeGrowthGlobal0,
                uint256 feeGrowthGlobal1
            ) = stateViewContract.getFeeGrowthGlobals(pools[i].pool);

            (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) = stateViewContract
                .getTickFeeGrowthOutside(pools[i].pool, tick);

            allPoolData.push(
                PoolData(
                    pools[i].pool,
                    feeGrowthGlobal0,
                    feeGrowthGlobal1,
                    feeGrowthOutside0X128,
                    feeGrowthOutside1X128,
                    liquidity,
                    sqrtPriceX96,
                    tick,
                    tickBitmap,
                    wordPos,
                    liquidityNet,
                    liquidityGross
                )
            );
        }

        // Return encoded data
        bytes memory abiEncodedData = abi.encode(allPoolData);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }

    function position(
        int24 tick
    ) internal pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick) & 0xFF);
    }
}
