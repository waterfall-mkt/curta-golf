// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IPurityChecker } from "../interfaces/IPurityChecker.sol";

/// @title EVM bytecode purity checker
/// @notice A purity checker checks whether a given contract is pure, i.e. that
/// it's restricted to a set of instructions/opcodes, by analyzing its bytecode.
contract PurityChecker is IPurityChecker {
    /// @inheritdoc IPurityChecker
    function check(bytes memory _code) external view override returns (bool) {
        // TODO
        return true;
    }
}
