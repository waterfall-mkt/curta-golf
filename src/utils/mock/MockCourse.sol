// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ICourse } from "../../interfaces/ICourse.sol";

/// @title A mock Curta Golf Course for testing
/// @author fiveoutofnine
contract MockCourse is ICourse {
    /// @inheritdoc ICourse
    function name() external pure returns (string memory) {
        return "Mock Course";
    }

    /// @inheritdoc ICourse
    function run(address _target, uint256 _seed) external view returns (uint32) {
        uint256 start = gasleft();

        // Generate inputs from `_seed`.
        uint256 a = _seed >> 128;
        uint256 b = _seed & 0xffffffffffffffffffffffffffffffff;

        // Run solution.
        uint256 c = IMockCourse(_target).add(a, b);

        unchecked {
            // Verify solution.
            if (c != a + b) revert IncorrectSolution();
        }

        // Return gas usage.
        return uint32(start - gasleft());
    }
}

/// @title The interface for `MockCourse`, a mock Curta Golf Course for testing
interface IMockCourse {
    /// @notice Adds two numbers together.
    /// @param _a The first number.
    /// @param _b The second number.
    /// @return The sum of `_a` and `_b`.
    function add(uint256 _a, uint256 _b) external pure returns (uint256);
}
