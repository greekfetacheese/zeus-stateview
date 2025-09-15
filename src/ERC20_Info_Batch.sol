// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Get the metadata for multiple ERC20 tokens */

interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ERC20InfoBatch {
    struct ERC20Info {
        address addr;
        string symbol;
        string name;
        uint256 totalSupply;
        uint8 decimals;
    }

    constructor(address[] memory tokens) {
        ERC20Info[] memory info = new ERC20Info[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            info[i] = ERC20Info(
                tokens[i],
                IERC20(tokens[i]).symbol(),
                IERC20(tokens[i]).name(),
                IERC20(tokens[i]).totalSupply(),
                IERC20(tokens[i]).decimals()
            );
        }

        bytes memory abiEncodedData = abi.encode(info);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}
