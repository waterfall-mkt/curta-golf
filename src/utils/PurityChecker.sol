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
            function perform(code, bitmap) -> ret {
                // `offset` is the memory position where the bytecode starts; we
                // add `0x20` to skip the portion that stores the length of the
                // bytecode.
                let offset := add(code, 0x20)
                // `end` is the memory position where the bytecode ends.
                let end := add(offset, mload(code))

                // Iterate through the opcodes in the bytecode until we reach
                // the end. For each byte that is an opcode (i.e. not data
                // pushed onto the stack via the `PUSH` opcodes), we break the
                // loop early if it is not allowed (i.e. the corresponding LSb
                // bit in `_allowedOpcodes` is `0`). Since `ret` is set to `0`,
                // or `false`, by default, this correctly results in `check`
                // returning `false` if the contract is not pure.
                for { let i := offset } lt(offset, end) { offset := add(offset, 1) } {
                    let opcode := byte(0, mload(offset))
                    // If the opcode is not allowed, the contract is not pure.
                    if iszero(and(shr(opcode, bitmap), 1)) { leave }
                    // `0xffffffff000000000000000000000000` is a bitmap where
                    // LSb bits `[0x5f + 1, 0x7f]` are 1, i.e. the `PUSH1`, ...,
                    // `PUSH32`, opcodes. We want to skip the number of bytes
                    // pushed onto the stack because they are arbitrary data,
                    // and we should not apply the purity check to them.
                    if and(shr(opcode, 0xffffffff000000000000000000000000), 1) {
                        // `opcode - 0x5f` is the number of bytes pushed onto
                        // the stack.
                        offset := add(offset, sub(opcode, 0x5f))
                    }
                }

                // If we reached the end of the bytecode, the contract is pure,
                // so return `true`.
                ret := 1
            }

            isPure := perform(_code, _allowedOpcodes)
        }
    }
}
