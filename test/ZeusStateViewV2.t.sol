// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {ZeusStateViewV2} from "../src/ZeusStateViewV2.sol";

contract ZeusStateViewV2Test is Test {
    ZeusStateViewV2 zeusStateView;
    address Alice;
    uint256 AliceKey;

    // Tokens
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    // Pools
    address public constant V2_USDC_DAI = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;
    address public constant V2_USDC_WETH = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

    address public constant V3_USDC_WETH = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address public constant V3_USDC_WETH_MEDIUM = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    address public constant V3_USDT_UNI = 0x3470447f3CecfFAc709D3e783A307790b0208d60;

    bytes32 public constant V4_LINK_USDC =
        bytes32(uint256(0x50ae33c238824aa1937d5d9f1766c487bca39b548f8d957994e8357eeeca));

    bytes32 public constant V4_USDC_USDT =
        bytes32(uint256(0x8aa4e11cbdf30eedc92100f4c8a31ff748e201d44712cc8c90d189edaa8e));

    bytes32 public constant V4_ETH_USDT =
        bytes32(uint256(0x50b00c1a5a8e582ec808e97e71598cd135206a9f9c548eab2ed73659e7ee));

    bytes32 public constant V4_ETH_UNI =
        bytes32(uint256(0x053f6a47ccba79e7d5d623173ed6dd5a31cf19c28bae0fb8276f4506295f));

    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant STATE_VIEW = 0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227;

    uint256 public ETH_AMOUNT = 10e18;
    uint256 public WETH_AMOUNT = 10e18;

    function setUp() public {
        zeusStateView = new ZeusStateViewV2();
        (address aliceAddr, uint256 aliceKey) = makeAddrAndKey("Alice");
        Alice = address(aliceAddr);
        AliceKey = aliceKey;
        deal(Alice, 10 ether);
        deal(WETH, Alice, WETH_AMOUNT);
    }

    function testGetETHBalanceSingle() public view {
        address[] memory owners = new address[](1);
        owners[0] = Alice;

        ZeusStateViewV2.ETHBalance[] memory balance = zeusStateView.getETHBalance(owners);

        for (uint256 i = 0; i < balance.length; i++) {
            assertEq(balance[i].owner, Alice);
            assertEq(balance[i].balance, Alice.balance);
        }
    }

    function testGetERC20BalanceSingle() public view {
        address[] memory tokens = new address[](1);
        tokens[0] = WETH;

        ZeusStateViewV2.ERC20Balance[] memory balance = zeusStateView.getERC20Balance(tokens, Alice);

        for (uint256 i = 0; i < balance.length; i++) {
            assertEq(balance[i].token, tokens[i]);
            assertEq(balance[i].balance, WETH_AMOUNT);
        }
    }

    function testGetERC20Info() public view {
        ZeusStateViewV2.ERC20Info memory info = zeusStateView.getERC20Info(WETH);

        assertEq(info.addr, WETH);
        assertEq(info.symbol, "WETH");
        assertEq(info.name, "Wrapped Ether");
        assertEq(info.decimals, 18);
    }

    function testGetERC20InfoBatch() public view {
        address[] memory tokens = new address[](2);
        tokens[0] = WETH;
        tokens[1] = UNI;

        ZeusStateViewV2.ERC20Info[] memory info = zeusStateView.getERC20InfoBatch(tokens);

        assertEq(info[0].addr, WETH);
        assertEq(info[0].symbol, "WETH");
        assertEq(info[0].name, "Wrapped Ether");
        assertEq(info[0].decimals, 18);

        assertEq(info[1].addr, UNI);
        assertEq(info[1].symbol, "UNI");
        assertEq(info[1].name, "Uniswap");
        assertEq(info[1].decimals, 18);
    }

    function testGetV3Pools() public view {
        ZeusStateViewV2.V3Pool[] memory pools = zeusStateView.getV3Pools(UNISWAP_V3_FACTORY, USDC, WETH);
        assertEq(pools.length, 4);
    }

    function testGetPools() public view {
        bytes32[] memory v4pools = new bytes32[](4);
        v4pools[0] = V4_LINK_USDC;
        v4pools[1] = V4_USDC_USDT;
        v4pools[2] = V4_ETH_USDT;
        v4pools[3] = V4_ETH_UNI;

        address[] memory baseTokens = new address[](4);
        baseTokens[0] = USDC;
        baseTokens[1] = USDT;
        baseTokens[2] = WETH;
        baseTokens[3] = DAI;

        ZeusStateViewV2.Pools memory pools = zeusStateView.getPools(
            UNISWAP_V2_FACTORY,
            UNISWAP_V3_FACTORY,
            STATE_VIEW,
            v4pools,
            baseTokens,
            UNI
        );
        
        assertEq(pools.v2Pools.length, 4);
        assertEq(pools.v3Pools.length, 4);
        assertEq(pools.v4Pools.length, 4);
    }

    function testValidateV4Pools() public view {
        bytes32[] memory pools = new bytes32[](4);
        pools[0] = V4_LINK_USDC;
        pools[1] = V4_USDC_USDT;
        pools[2] = V4_ETH_USDT;
        pools[3] = V4_ETH_UNI;

        bytes32[] memory validPools = zeusStateView.validateV4Pools(STATE_VIEW, pools);

        assertEq(validPools.length, 4);
    }

    function testGetPoolsState() public view {
        address[] memory v2pools = new address[](2);
        v2pools[0] = V2_USDC_DAI;
        v2pools[1] = V2_USDC_WETH;

        ZeusStateViewV2.V3Pool[] memory v3pools = new ZeusStateViewV2.V3Pool[](2);
        v3pools[0] = ZeusStateViewV2.V3Pool({addr: V3_USDC_WETH_MEDIUM, tokenA: USDC, tokenB: WETH, fee: 3000});
        v3pools[1] = ZeusStateViewV2.V3Pool({addr: V3_USDT_UNI, tokenA: USDT, tokenB: UNI, fee: 3000});

        ZeusStateViewV2.V4Pool[] memory v4pools = new ZeusStateViewV2.V4Pool[](2);
        v4pools[0] = ZeusStateViewV2.V4Pool({pool: V4_ETH_UNI, tickSpacing: 60});
        v4pools[1] = ZeusStateViewV2.V4Pool({pool: V4_LINK_USDC, tickSpacing: 60});

        ZeusStateViewV2.PoolsState memory poolsState = zeusStateView.getPoolsState(v2pools, v3pools, v4pools, STATE_VIEW);

        assertEq(poolsState.v2Reserves.length, 2);
        assertEq(poolsState.v3PoolsData.length, 2);
        assertEq(poolsState.v4PoolsData.length, 2);
    }
}
