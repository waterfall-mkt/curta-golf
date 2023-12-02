// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IPurityChecker } from "../interfaces/IPurityChecker.sol";

/// @title EVM bytecode purity checker
/// @author Sabnock01
/// @notice A purity checker checks whether a given contract is pure, i.e. that
/// it's restricted to a set of instructions/opcodes, by analyzing its bytecode.
contract PurityChecker is IPurityChecker {
    function check(bytes memory _code, uint256 _allowedOpcodes) external pure override returns (bool satisfied) {
        assembly ("memory-safe") {
            function isPush(opcode) -> ret {
                ret := and(gt(opcode, 0x5f), lt(opcode, 0x80))   
            }
            
            function perform(code, opcodeBitmap) -> ret {
                for {
                    let offset := add(code, 0x20)
                    let end := add(offset, mload(code))
                } lt(offset, end) {
                    offset := add(offset, 1)
                } {
                    let opcode := byte(0, mload(offset))
                    if iszero(and(shr(opcode, opcodeBitmap), 1)) {
                        // ret is set to false implicityly here
                        leave 
                    }

                    if isPush(opcode) {
                        // no logic needed for `PUSH0` which takes no args
                        let immLen := sub(opcode, 0x5f)
                        offset := add(offset, immLen)

                        // Check for push overreading
                        if iszero(lt(offset, end)) {
                            // ret is set as false implicitly here
                            leave
                        }
                    }
                }
            }
            satisfied := perform(_code, _allowedOpcodes)
        }
    }
}
