// SPDX-License-Identifier: MIT
import { IMockCourse } from "./MockCourse.sol";

/// @title An efficient solution to `MockCourse`.
/// @author fiveoutofnine
contract MockCourseSolutionEfficient is IMockCourse {
    /// @inheritdoc IMockCourse
    function add(uint256 _a, uint256 _b) external pure override returns (uint256) {
        unchecked {
            return _a + _b;
        }
    }
}

/// @title An inefficient solution to `MockCourse`.
/// @author fiveoutofnine
contract MockCourseSolutionInefficient is IMockCourse {
    /// @inheritdoc IMockCourse
    function add(uint256 _a, uint256 _b) external pure override returns (uint256) {
        // Waste some gas.
        for (uint256 i; i < 100; ++i) { }

        return _a + _b;
    }
}
