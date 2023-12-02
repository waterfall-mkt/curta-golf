// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/// @title The interface for a course on Curta Golf
/// @notice A course is a gas golfing challenge, where the goal is for players
/// to submit solutions that use as little gas as possible.
interface ICourse {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when the solution is incorrect.
    error IncorrectSolution();

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Returns the course's name.
    /// @return The course's name.
    function name() external pure returns (string memory);

    /// @notice Runs a solution submitted by a player against the course with
    /// inputs randomly generated from `_seed`.
    /// @dev `_target` will always be deployed by the `CurtaGolf` contract from
    /// player bytecode submissions. Similarly, `_seed` is used to generate the
    /// inputs, and it will also always be passed in by the `CurtaGolf`
    /// contract.
    /// @param _target The address of contract with the solution to run.
    /// @param _seed The seed used to generate the inputs for the solution.
    function run(address _target, uint256 _seed) external pure;
}
