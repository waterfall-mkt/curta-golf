// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { CurtaGolfPar } from "../CurtaGolfPar.sol";
import { ICourse } from "./ICourse.sol";
import { IPurityChecker } from "./IPurityChecker.sol";

/// @title The interface for Curta Golf
/// @notice Curta Golf is a king-of-the-hill style gas golfing protocol, where
/// the goal is for players to submit solutions to ``courses,'' or challenges,
/// to use the least gas possible. If a player's solution becomes the leading
/// solution (i.e. the least gas used) for a course, they become the ``King'' of
/// that course, and an NFT with the same ID is transferred to them. Additional
/// ``Par'' NFTs are minted to players who submit valid solutions even if they
/// are not the leading solution (see {CurtaGolfPar}; note: max 1 Par NFT per
/// (course, solver) pair).
interface ICurtaGolf {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when an address is the zero address.
    error AddressIsZeroAddress();

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
    /// @param blockNumber The block number of the commit.
    struct Commit {
        address player;
        uint96 blockNumber;
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
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice The Curta Golf Par contract.
    function curtaGolfPar() external view returns (CurtaGolfPar);

    /// @return The address of the renderer used to render tokens' metadata
    /// returned by {CurtaGolf.tokenURI}.
    function renderer() external view returns (address);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @return The total number of courses.
    function courseId() external view returns (uint32);

    /// @return The purity checker.
    function purityChecker() external view returns (IPurityChecker);

    /// @param _key The key of the commit.
    /// @return player The address of the player (i.e. the address that is
    /// making the commit and the submission).
    /// @return blockNumber The block number of the commit.
    function getCommit(bytes32 _key) external view returns (address player, uint96 blockNumber);

    /// @param _id The ID of the course.
    /// @param solutionCount The number of successful solutions submitted.
    /// @param kingCount The number of times the course has had a new King.
    function getCourse(uint32 _id)
        external
        view
        returns (ICourse course, uint32 gasUsed, uint32 solutionCount, uint32 kingCount);

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Adds a course to the contract.
    /// @param _course The address of the course.
    function addCourse(ICourse _course) external;

    /// @notice Commits a solution to a course to prevent front-running.
    /// @dev `_key` is computed as
    /// `keccak256(abi.encode(msg.sender, _solution, _salt)`, where `_solution`
    /// is the bytecode of the solution, and `_salt` is some random, secret
    /// number.
    /// @param _key The key of the commit.
    function commit(bytes32 _key) external;

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
