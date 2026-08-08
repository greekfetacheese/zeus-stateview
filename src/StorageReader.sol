// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title StorageReader
/// @notice Minimal bytecode injected onto a *target* account via `eth_call` state override
///         so `SLOAD` runs in that account's storage context.
///
/// ## Why this exists
/// The EVM has no `EXT_SLOAD`. A normal contract can only `SLOAD` **its own** storage.
///
/// ## How to use (single account, 1 RPC)
/// ```
/// eth_call({
///   to: target,
///   data: abi.encodeCall(StorageReader.readSlotsUint, (slots)),
/// }, blockNumber, /* state override */ {
///   [target]: { code: StorageReader.runtimeCode }
/// })
/// ```
/// Storage and nonce of `target` stay real; only code is temporarily replaced for the call.
///
/// ## Multi-account
/// Either:
/// 1. One eth_call per account (same runtime bytecode in each override), or
/// 2. Multicall3 as outer `to`, with StorageReader code overridden on every target, each
///    subcall = `readSlotsUint` against that account.
///
/// Do NOT deploy this as a permanent replacement for real contracts on-chain.
contract StorageReader {
    /// @notice Read arbitrary storage slots of *this* account (the `to` / overridden address).
    /// @param slots Storage slots to SLOAD.
    /// @return values Slot values, same order as `slots`.
    function readSlots(uint256[] calldata slots) external view returns (bytes32[] memory values) {
        uint256 len = slots.length;
        values = new bytes32[](len);
        for (uint256 i; i < len;) {
            uint256 slot = slots[i];
            bytes32 value;
            assembly ("memory-safe") {
                value := sload(slot)
            }
            values[i] = value;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Same as `readSlots` but returns `uint256` (handy for Alloy / revm U256).
    function readSlotsUint(uint256[] calldata slots) external view returns (uint256[] memory values) {
        uint256 len = slots.length;
        values = new uint256[](len);
        for (uint256 i; i < len;) {
            uint256 slot = slots[i];
            uint256 value;
            assembly ("memory-safe") {
                value := sload(slot)
            }
            values[i] = value;
            unchecked {
                ++i;
            }
        }
    }
}
