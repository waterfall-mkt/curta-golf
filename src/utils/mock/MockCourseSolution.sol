// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IMockCourse } from "./MockCourse.sol";

/// @title An efficient solution to `MockCourse`.
/// @author fiveoutofnine
/// @dev When compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer
/// runs, the contract has the following bytecode:
/// ```
/// 0x6080604052348015600f57600080fd5b5060a58061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063771602f714602d575b600080fd5b603c6038366004604e565b0190565b60405190815260200160405180910390f35b60008060408385031215606057600080fd5b5050803592602090910135915056fea264697066735822122053508e1f6f437dc11678aec86f624d167eb4ae75e36f622b6bf518e6edd2a99f64736f6c63430008150033
/// ```
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
/// @dev When compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer
/// runs, the contract has the following bytecode:
/// ```
/// 0x608060405234801561001057600080fd5b50610158806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063771602f714610030575b600080fd5b61004361003e366004610086565b610055565b60405190815260200160405180910390f35b6000805b60648110156100725761006b816100d7565b9050610059565b5061007d828461010f565b90505b92915050565b6000806040838503121561009957600080fd5b50508035926020909101359150565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8203610108576101086100a8565b5060010190565b80820180821115610080576100806100a856fea26469706673582212200d824e76c3f79d5d524f08c7f5df03e9eee461a0664d228713dc578a86c02fc564736f6c63430008150033
/// ```
contract MockCourseSolutionInefficient is IMockCourse {
    /// @inheritdoc IMockCourse
    function add(uint256 _a, uint256 _b) external pure override returns (uint256) {
        // Waste some gas.
        for (uint256 i; i < 100; ++i) { }

        return _a + _b;
    }
}

/// @title An incorrect solution to `MockCourse`.
/// @author fiveouofnine
/// @dev When compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer
/// runs, the contract has the following bytecode:
/// ```
/// 0x6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063771602f714602d575b600080fd5b603f60383660046051565b0160010190565b60405190815260200160405180910390f35b60008060408385031215606357600080fd5b5050803592602090910135915056fea2646970667358221220c0672b35ca81e6e3ee229462853d66fda7b44dc7daae20c26d00b79ac2e3821464736f6c63430008150033
/// ```
contract MockCourseSolutionIncorrect is IMockCourse {
    /// @inheritdoc IMockCourse
    function add(uint256 _a, uint256 _b) external pure override returns (uint256) {
        unchecked {
            return _a + _b + 1;
        }
    }
}
