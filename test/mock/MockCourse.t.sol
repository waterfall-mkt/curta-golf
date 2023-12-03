// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ICourse } from "../../src/interfaces/ICourse.sol";
import { BaseTest } from "../utils/BaseTest.sol";

/// @notice Unit tests for `MockCourse`, organized by functions.
contract MockCourseTest is BaseTest {
    // -------------------------------------------------------------------------
    // `name`
    // -------------------------------------------------------------------------

    /// @notice Test that calling `name` returns a string of length greater than
    /// zero.
    function test_name_ReturnsNonEmptyString() public {
        string memory name = mockCourse.name();
        assertGt(bytes(name).length, 0);
    }

    // -------------------------------------------------------------------------
    // `run`
    // -------------------------------------------------------------------------

    /// @notice Test that calling `run` with a correct solution does not revert
    /// against a fuzzed seed.
    /// @param _seed The seed to run the course with.
    function test_run_CorrectSolution_DoesNotRevert(uint256 _seed) public {
        mockCourse.run(address(mockSolution), _seed);
    }

    /// @notice Test that calling `run` with an incorrect solution reverts
    /// against a fuzzed seed.
    /// @param _seed The seed to run the course with.
    function test_run_IncorrectSolution_Reverts(uint256 _seed) public {
        vm.expectRevert(ICourse.IncorrectSolution.selector);
        mockCourse.run(address(mockSolutionIncorrect), _seed);
    }
}
