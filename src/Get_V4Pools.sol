//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStateView {
    function getLiquidity(
        bytes32 poolId
    ) external view returns (uint128 liquidity);
}

contract GetV4Pools {
    constructor(bytes32[] memory pools, address stateView) {
        IStateView stateViewContract = IStateView(stateView);
        bytes32[] memory validPools = new bytes32[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            uint128 liquidity = stateViewContract.getLiquidity(pools[i]);

            if (liquidity > 0) {
                validPools[i] = pools[i];
            }
        }

        // Return encoded data
        bytes memory abiEncodedData = abi.encode(validPools);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}
