// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {StorageReader} from "../src/StorageReader.sol";

/// @dev Simulates eth_call state overrides with `vm.etch` (replace code, keep storage).
contract StorageReaderTest is Test {
    StorageReader internal readerImpl;

    address internal constant TARGET_A = address(0xA11CE);
    address internal constant TARGET_B = address(0xB0B);

    function setUp() public {
        readerImpl = new StorageReader();
    }

    function testReadSlots_directWithEtch() public {
        // Plant known storage on a bare address, then etch reader code over it.
        vm.store(TARGET_A, bytes32(uint256(0)), bytes32(uint256(111)));
        vm.store(TARGET_A, bytes32(uint256(5)), bytes32(uint256(222)));
        vm.store(TARGET_A, bytes32(uint256(999)), bytes32(uint256(333)));
        vm.etch(TARGET_A, address(readerImpl).code);

        uint256[] memory slots = new uint256[](3);
        slots[0] = 0;
        slots[1] = 5;
        slots[2] = 999;

        uint256[] memory values = StorageReader(TARGET_A).readSlotsUint(slots);
        assertEq(values.length, 3);
        assertEq(values[0], 111);
        assertEq(values[1], 222);
        assertEq(values[2], 333);

        bytes32[] memory valuesB32 = StorageReader(TARGET_A).readSlots(slots);
        assertEq(uint256(valuesB32[0]), 111);
        assertEq(uint256(valuesB32[1]), 222);
        assertEq(uint256(valuesB32[2]), 333);
    }

    function testReadSlots_multiAccount_separateCalls() public {
        vm.store(TARGET_A, bytes32(uint256(1)), bytes32(uint256(42)));
        vm.store(TARGET_A, bytes32(uint256(2)), bytes32(uint256(43)));
        vm.store(TARGET_B, bytes32(uint256(7)), bytes32(uint256(77)));

        // Each account gets the same reader runtime via state override (vm.etch here).
        bytes memory code = address(readerImpl).code;
        vm.etch(TARGET_A, code);
        vm.etch(TARGET_B, code);

        uint256[] memory slotsA = new uint256[](2);
        slotsA[0] = 1;
        slotsA[1] = 2;
        uint256[] memory valuesA = StorageReader(TARGET_A).readSlotsUint(slotsA);
        assertEq(valuesA[0], 42);
        assertEq(valuesA[1], 43);

        uint256[] memory slotsB = new uint256[](1);
        slotsB[0] = 7;
        uint256[] memory valuesB = StorageReader(TARGET_B).readSlotsUint(slotsB);
        assertEq(valuesB[0], 77);
    }

    function testReadSlots_failsWithoutOverride() public {
        // No code at TARGET_A — staticcall returns success=false or empty/undecodable data.
        uint256[] memory slots = new uint256[](1);
        slots[0] = 0;

        (bool success, bytes memory data) =
            TARGET_A.staticcall(abi.encodeCall(StorageReader.readSlotsUint, (slots)));

        // Empty EOA: success can be true with empty returndata; either way there is no ABI array.
        bool ok = success && data.length >= 64;
        if (ok) {
            // If somehow code existed, decode would work — fail the test intent.
            uint256[] memory values = abi.decode(data, (uint256[]));
            assertEq(values.length, 0); // unreachable if real reader present with 1 slot
            revert("expected missing StorageReader code");
        }
    }

    function testReadSlots_empty() public {
        vm.etch(TARGET_A, address(readerImpl).code);
        uint256[] memory slots = new uint256[](0);
        uint256[] memory values = StorageReader(TARGET_A).readSlotsUint(slots);
        assertEq(values.length, 0);
    }
}
