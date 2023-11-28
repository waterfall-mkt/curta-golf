// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Test } from "forge-std/Test.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";

import { CurtaGolf } from "../../src/CurtaGolf.sol";
import { Par } from "../../src/Par.sol";
import { ICourse } from "../../src/interfaces/ICourse.sol";
import { IPurityChecker } from "../../src/interfaces/IPurityChecker.sol";
import { PurityChecker } from "../../src/utils/PurityChecker.sol";

/// @notice A base test contract for Curta Golf with events, labeled addresses,
/// and helper functions for testing. When `BaseTest` is deployed, it sets and
/// labels 3 addresses: `owner` (owner of the `CurtaGolf` deploy), `solver1`,
/// and `solver2`. Then, in `setUp`, it deploys an instance of `CurtaGolf`,
/// `Par`, and `PurityChecker`.
contract BaseTest is Test {
    // -------------------------------------------------------------------------
    // `CurtaGolf` events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a course is added to the contract.
    /// @param id The ID of the course.
    /// @param course The address of the course.
    event AddCourse(uint32 indexed id, ICourse indexed course);

    /// @notice Emitted when a commit for a solution is made.
    /// @param courseId The ID of the course.
    /// @param player The address of the player.
    /// @param key The key of the commit.
    event CommitSolution(uint32 indexed courseId, address indexed player, bytes32 key);

    /// @notice Emitted when a valid submission is made.
    /// @param courseId The ID of the course.
    /// @param recipient The address of the recipient.
    /// @param target The address of the deployed solution.
    event SubmitSolution(
        uint32 indexed courseId, address indexed recipient, address indexed target
    );

    /// @notice Emitted when a new purity checker is set.
    /// @param purityChecker The address of the new purity checker.
    event SetPurityChecker(IPurityChecker indexed purityChecker);

    /// @notice Emitted when a course gets a new King.
    /// @param courseId The ID of the course.
    /// @param recipient The address of the recipient.
    /// @param gasUsed The amount of gas used.
    event UpdateKing(uint32 indexed courseId, address indexed recipient, uint32 indexed gasUsed);

    // -------------------------------------------------------------------------
    // `ERC721` events
    // -------------------------------------------------------------------------

    /// @notice Emitted when the address approved to transfer a token is
    /// updated.
    /// @param owner The owner of the token.
    /// @param spender The address approved to transfer the token.
    /// @param id The ID of the token.
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    /// @notice Emitted when an operator to transfer all of an owner's tokens is
    /// updated.
    /// @param owner The owner of the tokens.
    /// @param operator The address approved to transfer all of the owner's
    /// tokens.
    /// @param approved The new approval status of the operator.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted when a token is transferred.
    /// @param from The address the token is transferred from.
    /// @param to The address the token is transferred to.
    /// @param id The ID of the token.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice Address of the owner
    address internal immutable owner;

    /// @notice Address to solver 1.
    address internal immutable solver1;

    /// @notice Address of a solver.
    address internal immutable solver2;

    // -------------------------------------------------------------------------
    // Contracts
    // -------------------------------------------------------------------------

    /// @notice The Curta Golf contract.
    CurtaGolf internal curtaGolf;

    /// @notice The Par contract.
    Par internal par;

    /// @notice The purity checker contract.
    PurityChecker internal purityChecker;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Sets and labels addresses for `owner`, `solver1`, and `solver2`.
    constructor() {
        owner = makeAddr("owner");
        solver1 = makeAddr("solver1");
        solver2 = makeAddr("solver2");
        vm.label(owner, "Curta Golf owner");
        vm.label(solver1, "Solver 1");
        vm.label(solver2, "Solver 2");
    }

    /// @notice Deploys an instance of `CurtaGolf`, `Par`, and `PurityChecker`.
    function setUp() public {
        // Transaction #1.
        purityChecker = new PurityChecker();

        // Curta Golf will be deployed on transaction #3, and Par will be
        // deployed on transaction #2.
        address curtaGolfAddress = LibRLP.computeAddress(address(this), 3);
        address parAddress = LibRLP.computeAddress(address(this), 2);

        // Transaction #2: Deploy Par.
        par = new Par(curtaGolfAddress);
        // Transaction #3: Deploy Curta Golf.
        curtaGolf = new CurtaGolf(par, purityChecker);

        // Transfer ownership of Curta Golf to `owner`.
        curtaGolf.transferOwnership(owner);

        // Label addresses.
        vm.label(parAddress, "Par");
        vm.label(curtaGolfAddress, "CurtaGolf");
    }
}
