// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Par } from "../Par.sol";
import { ICourse } from "./ICourse.sol";
import { IPurityChecker } from "./IPurityChecker.sol";

/// @title The interface for Curta Golf
/// @notice Curta Golf is a king-of-the-hill style gas golfing protocol, where
/// the goal is for players to submit solutions to ``courses,'' or challenges,
/// to use the least gas possible.
interface ICurtaGolf {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when an address is the zero address.
    error AddressIsZeroAddress();

    /// @notice Emitted when a commit is too new.
    /// @param _key The key of a commit.
    error CommitTooNew(bytes32 _key);

    /// @notice Emitted when a course does not exist.
    /// @param _id The ID of a course.
    error CourseDoesNotExist(uint32 _id);

    /// @notice Emitted when a key has already been committed.
    /// @param _key The key of a commit.
    error KeyAlreadyCommitted(bytes32 _key);

    /// @notice Emitted when a key has not been committed.
    /// @param _key The key of a commit.
    error KeyNotCommitted(bytes32 _key);

    /// @notice Emitted when a solution's bytecode contains unpermitted opcodes.
    error PollutedSolution();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice A struct containing data about a submission's commit.
    /// @param player The address of the player (i.e. the address that is making
    /// the commit and the submission).
    /// @param timestamp The block timestamp the commit was posted.
    struct Commit {
        address player;
        uint96 timestamp;
    }

    /// @notice A struct containing data about a course.
    /// @param course The address of the course.
    /// @param gasUsed The current leading solution's gas usage. If there have
    /// been no solutions submitted, `gasUsed` is 0 by default.
    /// @param solutionCount The number of successful solutions submitted.
    /// @param kingCount The number of times the course has had a new King.
    struct CourseData {
        ICourse course;
        uint32 gasUsed;
        uint32 solutionCount;
        uint32 kingCount;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a course is added to the contract.
    /// @param id The ID of the course.
    /// @param course The address of the course.
    event AddCourse(uint32 indexed id, ICourse indexed course);

    /// @notice Emitted when a commit for a solution is made.
    /// @param player The address of the player.
    /// @param key The key of the commit.
    event CommitSolution(address indexed player, bytes32 indexed key);

    /// @notice Emitted when new allowed opcodes are set for a course.
    /// @param courseId The ID of the course.
    /// @param allowedOpcodes The bitmap of allowed opcodes.
    event SetAllowedOpcodes(uint32 indexed courseId, uint256 indexed allowedOpcodes);

    /// @notice Emitted when a new purity checker is set.
    /// @param purityChecker The address of the new purity checker.
    event SetPurityChecker(IPurityChecker indexed purityChecker);

    /// @notice Emitted when a valid submission is made.
    /// @param courseId The ID of the course.
    /// @param recipient The address of the recipient.
    /// @param target The address of the deployed solution.
    /// @param gasUsed The amount of gas used.
    event SubmitSolution(
        uint32 indexed courseId, address indexed recipient, address target, uint32 indexed gasUsed
    );

    /// @notice Emitted when a course gets a new King.
    /// @param courseId The ID of the course.
    /// @param recipient The address of the recipient.
    /// @param gasUsed The amount of gas used.
    event UpdateKing(uint32 indexed courseId, address indexed recipient, uint32 indexed gasUsed);

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice Returns the Par contract.
    /// @return The Par contract.
    function par() external view returns (Par);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Returns the ID of the next course.
    /// @return The total number of courses.
    function courseId() external view returns (uint32);

    /// @notice Returns the purity checker contract.
    /// @return The purity checker contract.
    function purityChecker() external view returns (IPurityChecker);

    /// @notice Returns the bitmap of allowed opcodes for a given course ID.
    /// @dev Each bitmap is a `uint256`, where a `1` at the LSb position equal
    /// to the opcode's value indicates that the opcode is allowed. For example,
    /// if only the `0x5f` (95) opcode is allowed for some course, the bitmap
    /// would be `1 << 95`. To check if some opcode `opcode` is allowed,
    /// `(bitmap >> opcode) & 1` must be `1`.
    /// @param _id The ID of the course.
    /// @return A bitmap, where a 1 at the LSb position equal to the opcode's
    /// value indicates that the opcode is allowed.
    function getAllowedOpcodes(uint32 _id) external view returns (uint256);

    /// @param _key The key of the commit.
    /// @return player The address of the player (i.e. the address that is
    /// making the commit and the submission).
    /// @return timestamp The block timestamp the commit was posted.
    function getCommit(bytes32 _key) external view returns (address player, uint96 timestamp);

    /// @param _id The ID of the course.
    /// @return course The address of the course.
    /// @return gasUsed The current leading solution's gas usage.
    /// @return solutionCount The number of successful solutions submitted.
    /// @return kingCount The number of times the course has had a new King.
    function getCourse(uint32 _id)
        external
        view
        returns (ICourse course, uint32 gasUsed, uint32 solutionCount, uint32 kingCount);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Adds a course to the contract.
    /// @param _course The address of the course.
    /// @param _allowedOpcodes The bitmap of allowed opcodes, where a 1 at the
    /// LSb position equal to the opcode's value indicates the opcode is
    /// allowed.
    function addCourse(ICourse _course, uint256 _allowedOpcodes) external;

    /// @notice Commits a solution to a course to prevent front-running.
    /// @dev `_key` is computed as
    /// `keccak256(abi.encode(msg.sender, _solution, _salt)`, where `_solution`
    /// is the bytecode of the solution, and `_salt` is some random, secret
    /// number.
    /// @param _key The key of the commit.
    function commit(bytes32 _key) external;

    /// @notice Sets the allowed opcodes for a course.
    /// @dev Can only be called after the course has been added.
    /// @param _courseId The ID of the course.
    /// @param _allowedOpcodes The bitmap of allowed opcodes, where a 1 at the
    /// LSb position equal to the opcode's value indicates the opcode is
    /// allowed.
    function setAllowedOpcodes(uint32 _courseId, uint256 _allowedOpcodes) external;

    /// @notice Sets a new purity checker.
    /// @dev The purity checker may need to be updated according to new EVM
    /// changes, and `owner` is the only address that can call this function to
    /// update it.
    /// @param _purityChecker The address of the new purity checker.
    function setPurityChecker(IPurityChecker _purityChecker) external;

    /// @notice Submits a solution by revealing a previously committed solution.
    /// @param _courseId The ID of the course.
    /// @param _solution The bytecode of the solution.
    /// @param _recipient The address of the recipient.
    /// @param _salt The salt used to generate the key of the commit.
    function submit(uint32 _courseId, bytes memory _solution, address _recipient, uint256 _salt)
        external;

    /// @notice Submits a solution to a course directly, skipping the 2-step
    /// commit-reveal process. Only call this function if front-running is not
    /// a concern (e.g. the solution is not to become the leading solution).
    /// @param _courseId The ID of the course.
    /// @param _solution The bytecode of the solution.
    /// @param _recipient The address of the recipient.
    function submitDirectly(uint32 _courseId, bytes memory _solution, address _recipient)
        external;
}
