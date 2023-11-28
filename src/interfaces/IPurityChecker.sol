// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title The interface for a purity checker
/// @notice A purity checker checks whether a given contract is pure, i.e. that
/// it's restricted to a set of instructions/opcodes, by analyzing its bytecode.
interface IPurityChecker {
    /// @notice Checks whether the given bytecode `_code` is pure.
    /// @param _code The bytecode to check.
    /// @return bool Whether the given bytecode is pure.
    function check(bytes memory _code) external view returns (bool);
}
