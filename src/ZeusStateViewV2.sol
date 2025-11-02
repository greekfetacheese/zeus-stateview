// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {MetadataReaderLib} from "./lib/MetadataReader.sol";

/*
ZZZZZZZZZZZZZZZZZZZ
Z:::::::::::::::::Z
Z:::::::::::::::::Z
Z:::ZZZZZZZZ:::::Z
ZZZZZ     Z:::::Z      eeeeeeeeeeee    uuuuuu    uuuuuu      ssssssssss
        Z:::::Z      ee::::::::::::ee  u::::u    u::::u    ss::::::::::s
       Z:::::Z      e::::::eeeee:::::eeu::::u    u::::u  ss:::::::::::::s
      Z:::::Z      e::::::e     e:::::eu::::u    u::::u  s::::::ssss:::::s
     Z:::::Z       e:::::::eeeee::::::eu::::u    u::::u   s:::::s  ssssss
    Z:::::Z        e:::::::::::::::::e u::::u    u::::u     s::::::s
   Z:::::Z         e::::::eeeeeeeeeee  u::::u    u::::u        s::::::s
ZZZ:::::Z     ZZZZZe:::::::e           u:::::uuuu:::::u  ssssss   s:::::s
Z::::::ZZZZZZZZ:::Ze::::::::e          u:::::::::::::::uus:::::ssss::::::s
Z:::::::::::::::::Z e::::::::eeeeeeee   u:::::::::::::::us::::::::::::::s
Z:::::::::::::::::Z  ee:::::::::::::e    uu::::::::uu:::u s:::::::::::ss
ZZZZZZZZZZZZZZZZZZZ    eeeeeeeeeeeeee      uuuuuuuu  uuuu  sssssssssss

State view contract for Zeus
Github: https://github.com/greekfetacheese/zeus-stateview
*/

contract ZeusStateViewV2 {
    uint24 FEE_LOWEST = 100;
    uint24 FEE_LOW = 500;
    uint24 FEE_MEDIUM = 3000;
    uint24 FEE_HIGH = 10000;

    uint24[] feeTiers = [FEE_LOWEST, FEE_LOW, FEE_MEDIUM, FEE_HIGH];

    /// @notice Response of the `getETHBalance` function
    struct ETHBalance {
        address owner;
        uint256 balance;
    }

    /// @notice Response of the `getERC20Balance` function
    struct ERC20Balance {
        address token;
        uint256 balance;
    }

    /// @notice Response of the `getERC20Info` function
    struct ERC20Info {
        address addr;
        string symbol;
        string name;
        uint256 totalSupply;
        uint8 decimals;
    }

    /// @notice Response of the `getV2Pools` function
    struct V2Pool {
        address addr;
        address tokenA;
        address tokenB;
    }

    /// @notice Response of the `getV3Pools` function
    struct V3Pool {
        address addr;
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    /// @notice Response of the `getV2Reserves` function
    struct V2PoolReserves {
        address pool;
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }

    /// @notice Response of the `getV3PoolState` function
    struct V3PoolData {
        address pool;
        uint256 tokenABalance;
        uint256 tokenBBalance;
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

    /// @notice Response of the `getV4PoolState` function
    struct V4PoolData {
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

    /// @notice Response of the `getPoolsState` function
    struct PoolsState {
        V2PoolReserves[] v2Reserves;
        V3PoolData[] v3PoolsData;
        V4PoolData[] v4PoolsData;
    }

    /// @notice Response of the `getPools` function
    struct Pools {
        V2Pool[] v2Pools;
        V3Pool[] v3Pools;
        bytes32[] v4Pools;
    }

    /// @notice Argument for the `getV4PoolState` function
    struct V4Pool {
        bytes32 pool;
        int24 tickSpacing;
    }

    /// @notice Query the ETH balance of multiple addresses
    function getETHBalance(address[] memory owners) external view returns (ETHBalance[] memory) {
        ETHBalance[] memory balances = new ETHBalance[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = ETHBalance(owners[i], owners[i].balance);
        }
        return balances;
    }

    /// @notice Query the balance of multiple ERC20 tokens for a given owner
    function getERC20Balance(address[] memory tokens, address owner) external view returns (ERC20Balance[] memory) {
        ERC20Balance[] memory balances = new ERC20Balance[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = ERC20Balance(tokens[i], balanceOf(tokens[i], owner));
        }
        return balances;
    }

    /// @notice Get the metadata for an ERC20 token
    function getERC20Info(address token) external view returns (ERC20Info memory) {
        return _getERC20Info(token);
    }

    /// @notice Get the metadata for multiple ERC20 tokens
    function getERC20InfoBatch(address[] memory tokens) external view returns (ERC20Info[] memory) {
        ERC20Info[] memory info = new ERC20Info[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            info[i] = _getERC20Info(tokens[i]);
        }
        return info;
    }

    /// @notice Query the state of multiple V2/V3/V4 pools
    function getPoolsState(
        address[] memory v2pools,
        V3Pool[] memory v3pools,
        V4Pool[] memory v4pools,
        address stateView
    ) external view returns (PoolsState memory) {
        PoolsState memory poolsState = PoolsState({
            v2Reserves: _getV2Reserves(v2pools),
            v3PoolsData: _getV3PoolState(v3pools),
            v4PoolsData: _getV4PoolState(v4pools, stateView)
        });
        return poolsState;
    }

    /// @notice Get all possible V2/V3 pools based on token pair and all fee tiers
    /// @notice For V4 pools, it will validate the id's by checking the liquidity
    function getPools(
        address v2factory,
        address v3factory,
        address stateView,
        bytes32[] memory v4pools,
        address[] memory baseTokens,
        address quoteToken
    ) external view returns (Pools memory) {
        V2Pool[] memory v2Pools = new V2Pool[](baseTokens.length);

        for (uint256 i = 0; i < baseTokens.length; i++) {
            V2Pool memory pool = _getV2Pool(v2factory, baseTokens[i], quoteToken);
            if (pool.addr != address(0)) {
                v2Pools[i] = pool;
            }
        }

        V3Pool[] memory v3Pools = new V3Pool[](baseTokens.length * feeTiers.length);
        for (uint256 i = 0; i < baseTokens.length; i++) {
            v3Pools = _getV3Pools(v3factory, baseTokens[i], quoteToken);
        }

        bytes32[] memory v4Pools = _validateV4Pools(stateView, v4pools);

        return Pools({v2Pools: v2Pools, v3Pools: v3Pools, v4Pools: v4Pools});
    }

    /// @notice Get the V2 pool based on token pair
    function getV2Pool(address factory, address tokenA, address tokenB) external view returns (V2Pool memory) {
        return _getV2Pool(factory, tokenA, tokenB);
    }

    /// @notice Get all the possible V3 pools based on token pair and all fee tiers
    function getV3Pools(address factory, address tokenA, address tokenB) external view returns (V3Pool[] memory) {
        return _getV3Pools(factory, tokenA, tokenB);
    }

    /// @notice Validate the given V4 Pools
    /// @notice Returns an array of valid pools
    function validateV4Pools(address stateView, bytes32[] memory pools) external view returns (bytes32[] memory) {
        return _validateV4Pools(stateView, pools);
    }

    /// @notice Query the reserves of multiple V2 pools
    function getV2Reserves(address[] memory pools) external view returns (V2PoolReserves[] memory) {
        return _getV2Reserves(pools);
    }

    /// @notice Query the state of multiple V3 pools
    function getV3PoolState(V3Pool[] memory pools) external view returns (V3PoolData[] memory) {
        return _getV3PoolState(pools);
    }

    /// @notice Query the state of multiple V4 pools
    function getV4PoolState(V4Pool[] memory pools, address stateView) external view returns (V4PoolData[] memory) {
        return _getV4PoolState(pools, stateView);
    }

    // *****************************************************************************
    // *                                                                           *
    // *                               Helpers                                     *
    // *                                                                           *
    // *****************************************************************************

    function _getERC20Info(address token) internal view returns (ERC20Info memory) {
        string memory name = MetadataReaderLib.readName(token);
        string memory symbol = MetadataReaderLib.readSymbol(token);
        uint8 decimals = MetadataReaderLib.readDecimals(token);
        uint256 totalSupply = 0;
        try IERC20(token).totalSupply() returns (uint256 _supply) {
            totalSupply = _supply;
        } catch {}
        return ERC20Info(token, symbol, name, totalSupply, decimals);
    }

    function _getV2Pool(address factory, address tokenA, address tokenB) internal view returns (V2Pool memory) {
        address poolAddr = IV2Factory(factory).getPair(tokenA, tokenB);
        V2Pool memory v2Pool = V2Pool({addr: poolAddr, tokenA: tokenA, tokenB: tokenB});
        return v2Pool;
    }

    function _getV3Pools(address factory, address tokenA, address tokenB) internal view returns (V3Pool[] memory) {
        V3Pool[] memory pools = new V3Pool[](feeTiers.length);
        for (uint256 i = 0; i < feeTiers.length; i++) {
            address poolAddr = IV3Factory(factory).getPool(tokenA, tokenB, feeTiers[i]);
            if (poolAddr != address(0)) {
                V3Pool memory v3Pool = V3Pool({addr: poolAddr, tokenA: tokenA, tokenB: tokenB, fee: feeTiers[i]});
                pools[i] = v3Pool;
            }
        }
        return pools;
    }

    function _validateV4Pools(address stateView, bytes32[] memory pools) internal view returns (bytes32[] memory) {
        IStateView stateViewContract = IStateView(stateView);
        bytes32[] memory validPools = new bytes32[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            uint128 liquidity = stateViewContract.getLiquidity(pools[i]);

            if (liquidity > 0) {
                validPools[i] = pools[i];
            }
        }
        return validPools;
    }

    function _getV2Reserves(address[] memory pools) internal view returns (V2PoolReserves[] memory) {
        V2PoolReserves[] memory reserves = new V2PoolReserves[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pool(pools[i]).getReserves();
            V2PoolReserves memory poolReserves = V2PoolReserves({
                pool: pools[i],
                reserve0: reserve0,
                reserve1: reserve1,
                blockTimestampLast: blockTimestampLast
            });
            reserves[i] = poolReserves;
        }
        return reserves;
    }

    function _getV3PoolState(V3Pool[] memory pools) internal view returns (V3PoolData[] memory) {
        V3PoolData[] memory allPoolData = new V3PoolData[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            allPoolData[i] = getV3PoolData(pools[i]);
        }

        return allPoolData;
    }

    function getV3PoolData(V3Pool memory _pool) internal view returns (V3PoolData memory) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool.addr);

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();

        int24 tickSpacing = calcTickSpacing(_pool.fee);
        (int16 wordPos, ) = position(tick / tickSpacing);
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
                _pool.addr,
                balanceOf(_pool.tokenA, _pool.addr),
                balanceOf(_pool.tokenB, _pool.addr),
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

    function _getV4PoolState(V4Pool[] memory pools, address stateView) internal view returns (V4PoolData[] memory) {
        V4PoolData[] memory allPoolData = new V4PoolData[](pools.length);

        IStateView stateViewContract = IStateView(stateView);

        for (uint256 i = 0; i < pools.length; i++) {
            (uint160 sqrtPriceX96, int24 tick, , ) = stateViewContract.getSlot0(pools[i].pool);
            (int16 wordPos, ) = position(tick / pools[i].tickSpacing);

            uint256 tickBitmap = stateViewContract.getTickBitmap(pools[i].pool, wordPos);
            uint128 liquidity = stateViewContract.getLiquidity(pools[i].pool);

            (uint128 liquidityGross, int128 liquidityNet) = stateViewContract.getTickLiquidity(pools[i].pool, tick);

            (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) = stateViewContract.getFeeGrowthGlobals(pools[i].pool);

            (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) = stateViewContract.getTickFeeGrowthOutside(
                pools[i].pool,
                tick
            );

            allPoolData[i] = V4PoolData(
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
            );
        }

        return allPoolData;
    }

    function calcTickSpacing(uint24 fee) internal view returns (int24 tickSpacing) {
        if (fee <= FEE_LOWEST) return 1;
        else if (fee == FEE_LOW) return 10;
        else if (fee == FEE_MEDIUM) return 60;
        else if (fee == FEE_HIGH) return 200;
        else fee / 50;
    }

    function position(int24 tick) internal pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick) & 0xFF);
    }

    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount := mul(
                // The arguments of `mul` are evaluated from right to left.
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}

// *****************************************************************************
// *                                                                           *
// *                               Interfaces                                  *
// *                                                                           *
// *****************************************************************************

interface IERC20 {
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pool {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
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

interface IV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface IStateView {
    function getLiquidity(bytes32 poolId) external view returns (uint128 liquidity);
    function getSlot0(
        bytes32 poolId
    ) external view returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee);

    function getTickBitmap(bytes32 poolId, int16 tick) external view returns (uint256 tickBitmap);

    function getFeeGrowthGlobals(
        bytes32 poolId
    ) external view returns (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1);

    function getTickFeeGrowthOutside(
        bytes32 poolId,
        int24 tick
    ) external view returns (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128);

    function getTickLiquidity(
        bytes32 poolId,
        int24 tick
    ) external view returns (uint128 liquidityGross, int128 liquidityNet);
}
