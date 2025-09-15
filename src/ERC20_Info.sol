// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Get the metadata for an ERC20 token */

interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ERC20Info {
    struct ERC20 {
        string symbol;
        string name;
        uint256 totalSupply;
        uint8 decimals;
    }

    constructor(address token) {
        ERC20 memory info = ERC20(
            IERC20(token).symbol(),
            IERC20(token).name(),
            IERC20(token).totalSupply(),
            IERC20(token).decimals()
        );

        bytes memory abiEncodedData = abi.encode(info);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}
