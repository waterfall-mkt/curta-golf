// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IPurityChecker } from "../interfaces/IPurityChecker.sol";

/// @title EVM bytecode purity checker
/// @author fiveoutofnine
/// @author Sabnock01
/// @notice A purity checker checks whether a given contract is pure, i.e. that
/// it's restricted to a set of instructions/opcodes.
contract PurityChecker is IPurityChecker {
    /// @inheritdoc IPurityChecker
    function check(bytes memory _code, uint256 _allowedOpcodes)
        external
        pure
        override
        returns (bool isPure)
    {
        assembly ("memory-safe") {
            // Code is pure by default unless disallowed byte is found.
            isPure := 1

            // `offset` is the memory position where the bytecode starts; we
            // add `0x20` to skip the portion that stores the length of the
            // bytecode.
            let offset := add(_code, 0x20)
            // `end` is the memory position where the bytecode ends.
            let end := add(offset, mload(_code))

            for { } lt(offset, end) { } {
                let opcode := byte(0, mload(offset))

                // Set `isPure` to 0 if any indexed bit in the loop was ever 0.
                isPure := and(isPure, shr(opcode, _allowedOpcodes))

                // Always increments the offset by at least 1.
                // If an opcode is a PUSH1-PUSH32 opcode (byte ∈ [0x60, 0x80)) the resulting value
                // after subtracting 0x60 will be a valid index ∈ [0, 32). This is then indexed into
                // a byte array representing the push bytes of the opcodes (1-32). Bytes outside of
                // that range will result in an index larger than 31, which for `BYTE(n, x)` always
                // returns 0.
                offset :=
                    add(
                        add(offset, 1),
                        byte(
                            sub(opcode, 0x60),
                            0x0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
                        )
                    )
            }
        }
    }
}
