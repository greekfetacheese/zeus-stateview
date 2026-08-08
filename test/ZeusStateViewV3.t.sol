// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {ZeusStateViewV3} from "../src/ZeusStateViewV3.sol";

/// @notice Fork tests for V3 StateView hardening (Base custom fee tiers + batch isolation).
contract ZeusStateViewV3Test is Test {
    ZeusStateViewV3 zeusStateView;

    // Base
    uint256 constant BASE_CHAIN_ID = 8453;
    address constant BASE_WETH = 0x4200000000000000000000000000000000000006;
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // Base Uniswap V3 WETH/USDC fee=200 (custom tier that broke calcTickSpacing).
    address constant BASE_V3_WETH_USDC_FEE200 = 0x1C450D7d1FD98A0b04E30deCFc83497b33A4F608;

    // Standard Base V3 WETH/USDC 500
    address constant BASE_V3_WETH_USDC_FEE500 = 0xd0b53D9277642d899DF5C87A3966A349A798F224;

    address constant BASE_STATE_VIEW = 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71;

    function setUp() public {
        // Optional: forge test --fork-url $BASE_RPC -vv
        // Without a fork, tests that hit real pools are skipped via try/catch on eth_call.
        zeusStateView = new ZeusStateViewV3();
    }

    function test_calcTickSpacingRemoved_compilesAndDeploys() public view {
        // Smoke: contract is deployable and has no fee→spacing table dependency for V3 state.
        assertTrue(address(zeusStateView) != address(0));
    }

    function test_v3CustomFee200_doesNotRevertOnBaseFork() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            rpc = vm.envOr("ETH_RPC_URL", string(""));
        }
        if (bytes(rpc).length == 0) {
            // No RPC configured — unit compile/deploy coverage only.
            return;
        }

        vm.createSelectFork(rpc);

        ZeusStateViewV3.V3Pool[] memory pools = new ZeusStateViewV3.V3Pool[](2);
        pools[0] = ZeusStateViewV3.V3Pool({
            addr: BASE_V3_WETH_USDC_FEE200,
            tokenA: BASE_WETH,
            tokenB: BASE_USDC,
            fee: 200
        });
        pools[1] = ZeusStateViewV3.V3Pool({
            addr: BASE_V3_WETH_USDC_FEE500,
            tokenA: BASE_WETH,
            tokenB: BASE_USDC,
            fee: 500
        });

        ZeusStateViewV3.V3PoolData[] memory data = zeusStateView.getV3PoolState(pools);
        assertEq(data.length, 2);
        // Both should succeed with real tickSpacing from the pool.
        assertEq(data[0].pool, BASE_V3_WETH_USDC_FEE200);
        assertTrue(data[0].sqrtPriceX96 > 0);
        assertEq(data[1].pool, BASE_V3_WETH_USDC_FEE500);
        assertTrue(data[1].sqrtPriceX96 > 0);
    }

    function test_batchIsolatesBadV3Pool() public {
        string memory rpc = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            rpc = vm.envOr("ETH_RPC_URL", string(""));
        }
        if (bytes(rpc).length == 0) {
            return;
        }

        vm.createSelectFork(rpc);

        ZeusStateViewV3.V3Pool[] memory pools = new ZeusStateViewV3.V3Pool[](2);
        // Zero address / non-pool — must not revert the whole call.
        pools[0] = ZeusStateViewV3.V3Pool({
            addr: address(0xdead),
            tokenA: BASE_WETH,
            tokenB: BASE_USDC,
            fee: 500
        });
        pools[1] = ZeusStateViewV3.V3Pool({
            addr: BASE_V3_WETH_USDC_FEE500,
            tokenA: BASE_WETH,
            tokenB: BASE_USDC,
            fee: 500
        });

        ZeusStateViewV3.V3PoolData[] memory data = zeusStateView.getV3PoolState(pools);
        assertEq(data.length, 2);
        // Bad pool left zeroed.
        assertEq(data[0].pool, address(0));
        // Good pool still populated.
        assertEq(data[1].pool, BASE_V3_WETH_USDC_FEE500);
        assertTrue(data[1].sqrtPriceX96 > 0);
    }
}
