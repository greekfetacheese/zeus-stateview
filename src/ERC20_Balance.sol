// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Query the balance of multiple ERC20 tokens for a given owner */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20Balance {
    struct TokenBalance {
        address token;
        uint256 balance;
    }

    TokenBalance[] public balances;

    constructor(address[] memory tokens, address owner) {
        for (uint256 i = 0; i < tokens.length; i++) {
            balances.push(TokenBalance(
                tokens[i],
                IERC20(tokens[i]).balanceOf(owner)
            ));
        }
        bytes memory abiEncodedData = abi.encode(balances);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}