// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ICourse } from "../src/interfaces/ICourse.sol";
import { ICurtaGolf } from "../src/interfaces/ICurtaGolf.sol";
import { PurityChecker } from "../src/utils/PurityChecker.sol";
import { BaseTest } from "./utils/BaseTest.sol";

/// @notice Unit tests for `CurtaGolf`, organized by functions.
contract CurtaGolfTest is BaseTest {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The maximum number of seconds that must pass before a commit can
    /// be revealed.
    uint256 constant MIN_COMMIT_AGE = 60;

    // -------------------------------------------------------------------------
    // `par`
    // -------------------------------------------------------------------------

    /// @notice Test that `par` was set correctly in the constructor.
    function test_par_Equality() public {
        assertEq(address(curtaGolf.par()), address(par));
    }

    // -------------------------------------------------------------------------
    // `commit`
    // -------------------------------------------------------------------------

    /// @notice Test that committing a key that's already been committed
    /// reverts.
    /// @param _key The key to commit.
    function test_commit_KeyAlreadyCommitted_Reverts(bytes32 _key) public {
        curtaGolf.commit(_key);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.KeyAlreadyCommitted.selector, _key));
        curtaGolf.commit(_key);
    }

    /// @notice Test the emitted events and storage updates upon committing a
    /// key.
    /// @param _key The key to commit.
    function test_commit(bytes32 _key) public {
        // Check that the key has not been committed yet.
        {
            (address player, uint96 timestamp) = curtaGolf.getCommit(_key);
            assertEq(player, address(0));
            assertEq(timestamp, 0);
        }

        // Commit the key as `solver1`.
        vm.prank(solver1);
        vm.expectEmit(true, true, true, true);
        emit CommitSolution(solver1, _key);
        curtaGolf.commit(_key);

        // Check that the commit was stored correctly.
        {
            (address player, uint96 timestamp) = curtaGolf.getCommit(_key);
            assertEq(player, solver1);
            assertEq(timestamp, block.timestamp);
        }
    }

    // -------------------------------------------------------------------------
    // `submit`
    // -------------------------------------------------------------------------

    /// @notice Test that revealing a solution that was never committed reverts.
    /// @param _salt The salt used to compute the key.
    function test_submit_KeyNotCommitted_Reverts(uint256 _salt) public {
        bytes32 key = keccak256(abi.encode(solver1, EFFICIENT_SOLUTION, _salt));

        vm.prank(solver1);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.KeyNotCommitted.selector, key));
        curtaGolf.submit(1, EFFICIENT_SOLUTION, solver1, _salt);
    }

    /// @notice Test that revealing a solution too recently after committing the
    /// key reverts.
    /// @param _warpSeconds The number of seconds between committing the key and
    /// revealing the solution.
    function test_submit_CommitTooNew_Reverts(uint256 _warpSeconds) public {
        _warpSeconds = bound(_warpSeconds, 0, MIN_COMMIT_AGE - 1);
        bytes32 key = keccak256(abi.encode(solver1, EFFICIENT_SOLUTION, 0));

        // Commit the key as `solver1` at timestamp `0`.
        vm.warp(0);
        vm.prank(solver1);
        curtaGolf.commit(key);

        // Warp time.
        vm.warp(_warpSeconds);

        // Revert if the commit is too new.
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.CommitTooNew.selector, key));
        vm.prank(solver1);
        curtaGolf.submit(1, EFFICIENT_SOLUTION, solver1, 0);
    }

    /// @notice Test that submitting a solution to a nonexistent course reverts.
    function test_submit_NonexistentCourse_Reverts() public {
        bytes32 key = keccak256(abi.encode(solver1, EFFICIENT_SOLUTION, 0));

        // Commit the key.
        vm.prank(solver1);
        curtaGolf.commit(key);

        // Submit the solution to course 2.
        vm.warp(MIN_COMMIT_AGE + 1);
        vm.prank(solver1);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.CourseDoesNotExist.selector, 2));
        curtaGolf.submit(2, EFFICIENT_SOLUTION, solver1, 0);
    }

    /// @notice Test that submitting a solution with invalid opcodes reverts.
    function test_submit_PollutedSolution_Reverts() public {
        // Ban all opcodes.
        vm.prank(owner);
        curtaGolf.setAllowedOpcodes(1, 0);

        // Commit the key.
        bytes32 key = keccak256(abi.encode(solver1, EFFICIENT_SOLUTION, 0));
        vm.prank(solver1);
        curtaGolf.commit(key);

        // Submit the solution.
        vm.warp(MIN_COMMIT_AGE + 1);
        vm.prank(solver1);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.PollutedSolution.selector));
        curtaGolf.submit(1, EFFICIENT_SOLUTION, solver1, 0);
    }

    /// @notice Test that submitting an incorrect solution reverts.
    function test_submit_IncorrectSolution_Reverts() public {
        // Commit the key.
        bytes32 key = keccak256(abi.encode(solver1, INCORRECT_SOLUTION, 0));
        vm.prank(solver1);
        curtaGolf.commit(key);

        // Submit the incorrect solution.
        vm.warp(MIN_COMMIT_AGE + 1);
        vm.prank(solver1);
        vm.expectRevert();
        curtaGolf.submit(1, INCORRECT_SOLUTION, solver1, 0);
    }

    /// @notice Test the emitted events and storage updates upon submitting
    /// solutions in the following order:
    ///     1. `solver1` submits an inefficient solution but becomes the king.
    ///     2. `solver2` submits an efficient solution and becomes the new king.
    ///     3. `solver3` submits an inefficient solution and doesn't become the
    ///         new king.
    /// All solvers get `par` NFTs minted to them, but only `solver1` and
    /// `solver3` hold ownership of a King NFT.
    function test_submit() public {
        // Commit the keys for `solver1`, `solver2`, and `solver3`.
        bytes32 key1 = keccak256(abi.encode(solver1, INEFFICIENT_SOLUTION, 0));
        bytes32 key2 = keccak256(abi.encode(solver2, EFFICIENT_SOLUTION, 0));
        bytes32 key3 = keccak256(abi.encode(solver3, INEFFICIENT_SOLUTION, 0));
        vm.prank(solver1);
        curtaGolf.commit(key1);
        vm.prank(solver2);
        curtaGolf.commit(key2);
        vm.prank(solver3);
        curtaGolf.commit(key3);

        vm.warp(MIN_COMMIT_AGE + 1);

        // Check that there is no King for course 1.
        {
            (, uint32 gasUsed, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(gasUsed, 0);
            assertEq(solutionCount, 0);
            assertEq(kingCount, 0);
            vm.expectRevert("NOT_MINTED");
            curtaGolf.ownerOf(1);
        }
        // Check that all solvers have 0 King NFTs.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 0);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that all solvers have 0 Par NFTs.
        {
            assertEq(par.balanceOf(solver1), 0);
            assertEq(par.balanceOf(solver2), 0);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the inefficient solution as `solver1`.
        vm.prank(solver1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver1, 1);
        vm.expectEmit(true, true, false, false);
        emit UpdateKing(1, solver1, 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver1, (1 << 160) | uint256(uint160(solver1)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver1, address(0), 0);
        curtaGolf.submit(1, INEFFICIENT_SOLUTION, solver1, 0);

        // Check that there is 1 King and 1 solution for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 1);
            assertEq(kingCount, 1);
            assertEq(curtaGolf.ownerOf(1), solver1);
        }
        // Check that `solver1` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 1);
            assertEq(curtaGolf.balanceOf(solver2), 0);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that `solver1` has 1 Par NFT, and the others have 0.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 0);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the efficient solution as `solver2`.
        vm.prank(solver2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(solver1, solver2, 1);
        vm.expectEmit(true, true, false, false);
        emit UpdateKing(1, solver2, 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver2, (1 << 160) | uint256(uint160(solver2)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver2, address(0), 0);
        curtaGolf.submit(1, EFFICIENT_SOLUTION, solver2, 0);

        // Check that there is 2 Kings and 2 solutions for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 2);
            assertEq(kingCount, 2);
            assertEq(curtaGolf.ownerOf(1), solver2);
        }
        // Check that `solver2` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 1);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that `solver1` and `solver2` have 1 Par NFT each, and `solver3`
        // has 0.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 1);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the efficient solution as `solver3`.
        vm.prank(solver3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver3, (1 << 160) | uint256(uint160(solver3)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver3, address(0), 0);
        curtaGolf.submit(1, INEFFICIENT_SOLUTION, solver3, 0);

        // Check that there is 2 Kings and 3 solutions for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 3);
            assertEq(kingCount, 2);
            assertEq(curtaGolf.ownerOf(1), solver2);
        }
        // Check that `solver2` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 1);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check each solver has 1 Par NFT each.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 1);
            assertEq(par.balanceOf(solver3), 1);
        }
    }

    // -------------------------------------------------------------------------
    // `submitDirectly`
    // -------------------------------------------------------------------------

    /// @notice Test the emitted events and storage updates upon submitting
    /// solutions in the following order:
    ///     1. `solver1` submits an inefficient solution but becomes the king.
    ///     2. `solver2` submits an efficient solution and becomes the new king.
    ///     3. `solver3` submits an inefficient solution and doesn't become the
    ///         new king.
    /// All solvers get `par` NFTs minted to them, but only `solver1` and
    /// `solver3` hold ownership of a King NFT.
    function test_submitDirectly() public {
        // Check that there is no King for course 1.
        {
            (, uint32 gasUsed, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(gasUsed, 0);
            assertEq(solutionCount, 0);
            assertEq(kingCount, 0);
            vm.expectRevert("NOT_MINTED");
            curtaGolf.ownerOf(1);
        }
        // Check that all solvers have 0 King NFTs.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 0);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that all solvers have 0 Par NFTs.
        {
            assertEq(par.balanceOf(solver1), 0);
            assertEq(par.balanceOf(solver2), 0);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the inefficient solution as `solver1`.
        vm.prank(solver1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver1, 1);
        vm.expectEmit(true, true, false, false);
        emit UpdateKing(1, solver1, 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver1, (1 << 160) | uint256(uint160(solver1)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver1, address(0), 0);
        curtaGolf.submitDirectly(1, INEFFICIENT_SOLUTION, solver1);

        // Check that there is 1 King and 1 solution for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 1);
            assertEq(kingCount, 1);
            assertEq(curtaGolf.ownerOf(1), solver1);
        }
        // Check that `solver1` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 1);
            assertEq(curtaGolf.balanceOf(solver2), 0);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that `solver1` has 1 Par NFT, and the others have 0.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 0);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the efficient solution as `solver2`.
        vm.prank(solver2);
        vm.expectEmit(true, true, true, true);
        emit Transfer(solver1, solver2, 1);
        vm.expectEmit(true, true, false, false);
        emit UpdateKing(1, solver2, 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver2, (1 << 160) | uint256(uint160(solver2)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver2, address(0), 0);
        curtaGolf.submitDirectly(1, EFFICIENT_SOLUTION, solver2);

        // Check that there is 2 Kings and 2 solutions for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 2);
            assertEq(kingCount, 2);
            assertEq(curtaGolf.ownerOf(1), solver2);
        }
        // Check that `solver2` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 1);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check that `solver1` and `solver2` have 1 Par NFT each, and `solver3`
        // has 0.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 1);
            assertEq(par.balanceOf(solver3), 0);
        }

        // Submit the efficient solution as `solver3`.
        vm.prank(solver3);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), solver3, (1 << 160) | uint256(uint160(solver3)));
        vm.expectEmit(true, true, false, false);
        emit SubmitSolution(1, solver3, address(0), 0);
        curtaGolf.submitDirectly(1, INEFFICIENT_SOLUTION, solver3);

        // Check that there is 2 Kings and 3 solutions for course 1.
        {
            (,, uint32 solutionCount, uint32 kingCount) = curtaGolf.getCourse(1);
            assertEq(solutionCount, 3);
            assertEq(kingCount, 2);
            assertEq(curtaGolf.ownerOf(1), solver2);
        }
        // Check that `solver2` has 1 King NFT, and the others have 0.
        {
            assertEq(curtaGolf.balanceOf(solver1), 0);
            assertEq(curtaGolf.balanceOf(solver2), 1);
            assertEq(curtaGolf.balanceOf(solver3), 0);
        }
        // Check each solver has 1 Par NFT each.
        {
            assertEq(par.balanceOf(solver1), 1);
            assertEq(par.balanceOf(solver2), 1);
            assertEq(par.balanceOf(solver3), 1);
        }
    }

    // -------------------------------------------------------------------------
    // `addCourse`
    // -------------------------------------------------------------------------

    /// @notice Test that adding a course as not `owner` reverts.
    function test_addCourse_NotOwner_Unauthorized(address _sender) public {
        vm.assume(_sender != owner);
        vm.expectRevert("UNAUTHORIZED");
        curtaGolf.addCourse(mockCourse, type(uint256).max);
    }

    /// @notice Test that adding a course whose address is `address(0)` reverts.
    function test_addCourse_ZeroAddress_Reverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.AddressIsZeroAddress.selector));
        curtaGolf.addCourse(ICourse(address(0)), type(uint256).max);
    }

    /// @notice Test the emitted events and storage updates upon adding a
    /// course.
    function test_addCourse() public {
        // Check that course #2 doesn't exist.
        {
            (ICourse course, uint32 gasUsed, uint32 solutionCount, uint32 kingCount) =
                curtaGolf.getCourse(2);
            assertEq(address(course), address(0));
            assertEq(gasUsed, 0);
            assertEq(solutionCount, 0);
            assertEq(kingCount, 0);
            assertEq(curtaGolf.getAllowedOpcodes(2), 0);
        }

        // Add the course.
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit SetAllowedOpcodes(2, type(uint256).max);
        vm.expectEmit(true, true, true, true);
        emit AddCourse(2, mockCourse);
        curtaGolf.addCourse(mockCourse, type(uint256).max);

        // Check that the course was added correctly.
        {
            (ICourse course, uint32 gasUsed, uint32 solutionCount, uint32 kingCount) =
                curtaGolf.getCourse(2);
            assertEq(address(course), address(mockCourse));
            assertEq(gasUsed, 0);
            assertEq(solutionCount, 0);
            assertEq(kingCount, 0);
            assertEq(curtaGolf.getAllowedOpcodes(2), type(uint256).max);
        }
    }

    // -------------------------------------------------------------------------
    // `setAllowedOpcodes`
    // -------------------------------------------------------------------------

    /// @notice Test that setting new opcodes as not `owner` reverts.
    function test_setAllowedOpcodes_NotOwner_Unauthorized(address _sender) public {
        vm.assume(_sender != owner);
        vm.expectRevert("UNAUTHORIZED");
        curtaGolf.setAllowedOpcodes(1, type(uint256).max - 1);
    }

    /// @notice Test that setting opcodes for a nonexistent course reverts.
    function test_setAllowedOpcodes_CourseDoesNotExist_Reverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.CourseDoesNotExist.selector, 2));
        curtaGolf.setAllowedOpcodes(2, type(uint256).max);
    }

    /// @notice Test the emitted events and storage updates upon setting new
    /// opcodes for a course.
    function test_setAllowedOpcodes() public {
        // Check that the opcodes for course #1 prior to setting new opcodes.
        assertEq(curtaGolf.getAllowedOpcodes(1), type(uint256).max);

        // Set new opcodes for course #1.
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit SetAllowedOpcodes(1, type(uint256).max - 1);
        curtaGolf.setAllowedOpcodes(1, type(uint256).max - 1);

        // Check that the opcodes for course #1 were set correctly.
        assertEq(curtaGolf.getAllowedOpcodes(1), type(uint256).max - 1);
    }

    // -------------------------------------------------------------------------
    // `setPurityChecker`
    // -------------------------------------------------------------------------

    /// @notice Test that setting the purity checker as not `owner` reverts.
    function test_setPurityChecker_NotOwner_Unauthorized(address _sender) public {
        vm.assume(_sender != owner);
        vm.expectRevert("UNAUTHORIZED");
        curtaGolf.setPurityChecker(purityChecker);
    }

    /// @notice Test that setting the purity checker to `address(0)` reverts.
    function test_setPurityChecker_ZeroAddress_Reverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(ICurtaGolf.AddressIsZeroAddress.selector));
        curtaGolf.setPurityChecker(PurityChecker(address(0)));
    }

    /// @notice Test the emitted events and storage updates upon setting a new
    /// purity checker.
    function test_setPurityChecker() public {
        // Check the purity checker prior to setting a new one.
        assertEq(address(curtaGolf.purityChecker()), address(purityChecker));

        // Deploy new purity checker, and set it as Curta Golf's new purity
        // checker.
        PurityChecker newPurityChecker = new PurityChecker();
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit SetPurityChecker(newPurityChecker);
        curtaGolf.setPurityChecker(newPurityChecker);

        // Check that the purity checker has been set to the new one.
        assertEq(address(curtaGolf.purityChecker()), address(newPurityChecker));
    }

    // -------------------------------------------------------------------------
    // `tokenURI`
    // -------------------------------------------------------------------------

    /// @notice Test that calling `tokenURI` on an unminted token reverts.
    function test_tokenURI_UnmintedToken_Reverts() public {
        vm.expectRevert("NOT_MINTED");
        curtaGolf.tokenURI(0);
    }

    /// @notice Test that calling `tokenURI` on a minted token succeeds.
    function test_tokenURI_MintedToken_Succeeds() public {
        curtaGolf.submitDirectly(1, EFFICIENT_SOLUTION, solver1);
        curtaGolf.tokenURI(1);
    }
}
