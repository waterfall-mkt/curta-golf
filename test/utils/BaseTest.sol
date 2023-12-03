// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Test } from "forge-std/Test.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";

import { CurtaGolf } from "../../src/CurtaGolf.sol";
import { Par } from "../../src/Par.sol";
import { ICourse } from "../../src/interfaces/ICourse.sol";
import { IPurityChecker } from "../../src/interfaces/IPurityChecker.sol";
import { PurityChecker } from "../../src/utils/PurityChecker.sol";
import { MockCourse, IMockCourse } from "../../src/utils/mock/MockCourse.sol";
import {
    MockCourseSolutionEfficient,
    MockCourseSolutionIncorrect
} from "../../src/utils/mock/MockCourseSolution.sol";

/// @notice A base test contract for Curta Golf with constants for sample
/// solutions, events, labeled addresses, and helper functions for testing. When
/// `BaseTest` is deployed, it sets and labels 3 addresses: `owner` (owner of
/// the `CurtaGolf` deploy), `solver1`, and `solver2`. Then, in `setUp`, it
/// deploys an instance of `CurtaGolf`, `MockCourse`, `Par`, `PurityChecker`,
/// and adds `MockCourse` to `CurtaGolf` as `owner` with every opcode allowed.
contract BaseTest is Test {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice Bytecode of an efficient solution to `MockCourse`.
    /// @dev The bytecode outputted when `MockCourseSolutionEfficient` is
    /// compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer runs.
    bytes constant EFFICIENT_SOLUTION =
        hex"6080604052348015600f57600080fd5b5060a58061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063771602f714602d575b600080fd5b603c6038366004604e565b0190565b60405190815260200160405180910390f35b60008060408385031215606057600080fd5b5050803592602090910135915056fea264697066735822122053508e1f6f437dc11678aec86f624d167eb4ae75e36f622b6bf518e6edd2a99f64736f6c63430008150033";

    /// @notice Bytecode of an incorrect solution to `MockCourse`.
    /// @dev The bytecode outputted when `MockCourseSolutionIncorrect` is
    /// compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer runs.
    bytes constant INCORRECT_SOLUTION =
        hex"6080604052348015600f57600080fd5b5060a88061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063771602f714602d575b600080fd5b603f60383660046051565b0160010190565b60405190815260200160405180910390f35b60008060408385031215606357600080fd5b5050803592602090910135915056fea2646970667358221220c0672b35ca81e6e3ee229462853d66fda7b44dc7daae20c26d00b79ac2e3821464736f6c63430008150033";

    /// @notice Bytecode of an inefficient solution to `MockCourse`.
    /// @dev The bytecode outputted when `MockCourseSolutionInefficient` is
    /// compiled with `0.8.21+commit.d9974bed` and `1_000_000` optimizer runs.
    bytes constant INEFFICIENT_SOLUTION =
        hex"608060405234801561001057600080fd5b50610158806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063771602f714610030575b600080fd5b61004361003e366004610086565b610055565b60405190815260200160405180910390f35b6000805b60648110156100725761006b816100d7565b9050610059565b5061007d828461010f565b90505b92915050565b6000806040838503121561009957600080fd5b50508035926020909101359150565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8203610108576101086100a8565b5060010190565b80820180821115610080576100806100a856fea26469706673582212200d824e76c3f79d5d524f08c7f5df03e9eee461a0664d228713dc578a86c02fc564736f6c63430008150033";

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

    /// @notice An incorrect solution to `MockCourse`.
    IMockCourse internal mockSolutionIncorrect;

    /// @notice A mock Curta Golf Course.
    ICourse internal mockCourse;

    /// @notice A solution to `MockCourse`.
    IMockCourse internal mockSolution;

    /// @notice The Par contract.
    Par internal par;

    /// @notice The purity checker contract.
    PurityChecker internal purityChecker;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    /// @notice Sets and labels addresses for `owner`, `solver1`, `solver2`, and
    /// sets the .
    constructor() {
        // Set addresses.
        owner = makeAddr("owner");
        solver1 = makeAddr("solver1");
        solver2 = makeAddr("solver2");
        vm.label(owner, "Curta Golf owner");
        vm.label(solver1, "Solver 1");
        vm.label(solver2, "Solver 2");
    }

    /// @notice Deploys an instance of `CurtaGolf`, `MockCourse`, `Par`,
    /// `PurityChecker`, and adds `MockCourse` to `CurtaGolf` as `owner` with
    /// every opcode allowed.
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
        // Transaction #4: Deploy the mock course.
        mockCourse = new MockCourse();

        // Transfer ownership of Curta Golf to `owner`.
        curtaGolf.transferOwnership(owner);

        // Add the mock course to Curta Golf with every opcode allowed.
        vm.prank(owner);
        curtaGolf.addCourse(mockCourse, type(uint256).max);

        // Deploy an instance of `MockCourseSolutionIncorrect`.
        mockSolutionIncorrect = new MockCourseSolutionIncorrect();

        // Deploy an instance of `MockCourseSolutionEfficient`.
        mockSolution = new MockCourseSolutionEfficient();

        // Label addresses.
        vm.label(address(par), "`Par`");
        vm.label(address(curtaGolf), "`CurtaGolf`");
        vm.label(address(mockCourse), "`MockCourse`");
        vm.label(address(mockSolutionIncorrect), "`MockSolutionIncorrect`");
        vm.label(address(mockSolution), "`MockSolutionEfficient`");
    }
}
