// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {ZeusStateView} from "../src/ZeusStateView.sol";

contract ZeusStateViewTest is Test {
    ZeusStateView zeusStateView;
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
    address public constant V3_USDC_WETH = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address public constant V3_USDC_WETH_MEDIUM = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    address public constant V3_USDT_UNI = 0x3470447f3CecfFAc709D3e783A307790b0208d60;

    bytes32 public constant LINK_USDC =
        bytes32(uint256(0x50ae33c238824aa1937d5d9f1766c487bca39b548f8d957994e8357eeeca));
    bytes32 public constant USDC_USDT =
        bytes32(uint256(0x8aa4e11cbdf30eedc92100f4c8a31ff748e201d44712cc8c90d189edaa8e));
    bytes32 public constant ETH_USDT = bytes32(uint256(0x50b00c1a5a8e582ec808e97e71598cd135206a9f9c548eab2ed73659e7ee));
    bytes32 public constant ETH_UNI = bytes32(uint256(0x053f6a47ccba79e7d5d623173ed6dd5a31cf19c28bae0fb8276f4506295f));

    address public constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant STATE_VIEW = 0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227;

    uint256 public ETH_AMOUNT = 10e18;
    uint256 public WETH_AMOUNT = 10e18;

    function setUp() public {
        zeusStateView = new ZeusStateView();
        (address aliceAddr, uint256 aliceKey) = makeAddrAndKey("Alice");
        Alice = address(aliceAddr);
        AliceKey = aliceKey;
        deal(Alice, 10 ether);
        deal(WETH, Alice, WETH_AMOUNT);
    }

    function testGetETHBalanceSingle() public view {
        address[] memory owners = new address[](1);
        owners[0] = Alice;

        ZeusStateView.ETHBalance[] memory balance = zeusStateView.getETHBalance(owners);

        for (uint256 i = 0; i < balance.length; i++) {
            assertEq(balance[i].owner, Alice);
            assertEq(balance[i].balance, Alice.balance);
        }
    }

    function testGetERC20BalanceSingle() public view {
        address[] memory tokens = new address[](1);
        tokens[0] = WETH;

        ZeusStateView.ERC20Balance[] memory balance = zeusStateView.getERC20Balance(tokens, Alice);

        for (uint256 i = 0; i < balance.length; i++) {
            assertEq(balance[i].token, tokens[i]);
            assertEq(balance[i].balance, WETH_AMOUNT);
        }
    }

    function testGetERC20Info() public view {
        ZeusStateView.ERC20Info memory info = zeusStateView.getERC20Info(WETH);

        assertEq(info.addr, WETH);
        assertEq(info.symbol, "WETH");
        assertEq(info.name, "Wrapped Ether");
        assertEq(info.decimals, 18);
    }

    function testGetERC20InfoBatch() public view {
        address[] memory tokens = new address[](2);
        tokens[0] = WETH;
        tokens[1] = UNI;

        ZeusStateView.ERC20Info[] memory info = zeusStateView.getERC20InfoBatch(tokens);

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
        ZeusStateView.V3Pool[] memory pools = zeusStateView.getV3Pools(UNISWAP_V3_FACTORY, USDC, WETH);
        assertEq(pools.length, 4);
    }

    function testValidateV4Pools() public view {
        bytes32[] memory pools = new bytes32[](4);
        pools[0] = LINK_USDC;
        pools[1] = USDC_USDT;
        pools[2] = ETH_USDT;
        pools[3] = ETH_UNI;

        bytes32[] memory validPools = zeusStateView.validateV4Pools(STATE_VIEW, pools);

        assertEq(validPools.length, 4);
    }

    function testGetV2Reserves() public view {
        address[] memory pools = new address[](1);
        pools[0] = V2_USDC_DAI;

        ZeusStateView.V2PoolReserves[] memory reserves = zeusStateView.getV2Reserves(pools);

        assertEq(reserves.length, 1);
        assertEq(reserves[0].pool, V2_USDC_DAI);
    }

    function testgetV3PoolState() public view {
        ZeusStateView.V3Pool[] memory pools = new ZeusStateView.V3Pool[](1);
        pools[0] = ZeusStateView.V3Pool({addr: V3_USDC_WETH_MEDIUM, tokenA: USDC, tokenB: WETH, fee: 3000});

        ZeusStateView.V3PoolData[] memory poolData = zeusStateView.getV3PoolState(pools);
        assertEq(poolData.length, 1);
    }

    function testgetV3PoolState2() public view {
        ZeusStateView.V3Pool[] memory pools = new ZeusStateView.V3Pool[](2);
        pools[0] = ZeusStateView.V3Pool({addr: V3_USDC_WETH, tokenA: USDC, tokenB: WETH, fee: 500});
        pools[1] = ZeusStateView.V3Pool({addr: V3_USDT_UNI, tokenA: USDT, tokenB: UNI, fee: 3000});

        ZeusStateView.V3PoolData[] memory poolData = zeusStateView.getV3PoolState(pools);
        assertEq(poolData.length, 2);
    }

    function testgetV4PoolState() public view {
        ZeusStateView.V4Pool[] memory pools = new ZeusStateView.V4Pool[](1);
        pools[0] = ZeusStateView.V4Pool({pool: ETH_UNI, tickSpacing: 60});

        ZeusStateView.V4PoolData[] memory poolData = zeusStateView.getV4PoolState(pools, STATE_VIEW);
        assertEq(poolData.length, 1);
    }
}
