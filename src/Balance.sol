// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** @dev Query the ETH balance of multiple addresses */


contract ETHBalance {
    struct Balance {
        address owner;
        uint256 balance;
    }

    Balance[] public balances;

    constructor(address[] memory owners) {
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 balance = owners[i].balance;
            balances.push(Balance(owners[i], balance));
        }
        bytes memory abiEncodedData = abi.encode(balances);
        assembly {
            let dataStart := add(abiEncodedData, 0x20)
            let dataLength := mload(abiEncodedData)
            return(dataStart, dataLength)
        }
    }
}