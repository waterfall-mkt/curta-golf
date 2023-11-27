// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Owned } from "solmate/auth/Owned.sol";

import { Par } from "./Par.sol";
import { ICourse } from "./interfaces/ICourse.sol";
import { ICurtaGolf } from "./interfaces/ICurtaGolf.sol";
import { IPurityChecker } from "./interfaces/IPurityChecker.sol";
import { KingERC721 } from "./tokens/KingERC721.sol";

/// @title Curta Golf
/// @author fiveoutofnine
/// @notice Curta Golf is a king-of-the-hill style gas golfing protocol, where
/// the goal is for players to submit solutions to ``courses,'' or challenges,
/// to use the least gas possible. If a player's solution becomes the leading
/// solution (i.e. the least gas used) for a course, they become the ``King'' of
/// that course, and an NFT with the same ID is transferred to them. Additional
/// ``Par'' NFTs are minted to players who submit valid solutions even if they
/// are not the leading solution (see {Par}; note: max 1 Par NFT per (course,
/// solver) pair).
contract CurtaGolf is ICurtaGolf, KingERC721, Owned {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The maximum number of seconds that must pass before a commit can
    /// be revealed.
    uint256 constant MIN_COMMIT_AGE = 60;

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    Par public immutable override par;

    /// @inheritdoc ICurtaGolf
    address public immutable override renderer;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    uint32 public override courseId;

    /// @inheritdoc ICurtaGolf
    IPurityChecker public override purityChecker;

    /// @inheritdoc ICurtaGolf
    mapping(bytes32 key => Commit commit) public override getCommit;

    /// @inheritdoc ICurtaGolf
    mapping(uint32 courseId => CourseData courseData) public override getCourse;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _par The Par contract.
    /// @param _renderer The address of the renderer used to render tokens'
    /// metadata.
    constructor(Par _par, address _renderer) KingERC721("Curta Golf", "KING") Owned(msg.sender) {
        par = _par;
        renderer = _renderer;
    }

    // -------------------------------------------------------------------------
    // Player functions
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    function commit(bytes32 _key) external {
        // Revert if the code has already been committed.
        if (getCommit[_key].player != address(0)) revert KeyAlreadyCommitted(_key);

        // Commit the key.
        getCommit[_key] = Commit({ player: msg.sender, timestamp: uint96(block.timestamp) });
    }

    /// @inheritdoc ICurtaGolf
    function submit(uint32 _courseId, bytes memory _solution, address _recipient, uint256 _salt)
        external
    {
        // Compute key.
        bytes32 key = keccak256(abi.encode(msg.sender, _solution, _salt));

        Commit memory commitData = getCommit[key];
        // Revert if the corresponding commit was never made.
        if (commitData.player == address(0)) revert KeyNotCommitted(key);

        // Revert if the commit is too new.
        unchecked {
            if (uint256(commitData.timestamp) + MIN_COMMIT_AGE > block.timestamp) {
                revert CommitTooNew(key);
            }
        }

        _submit(_courseId, _solution, _recipient);
    }

    /// @inheritdoc ICurtaGolf
    function submitDirectly(uint32 _courseId, bytes memory _solution, address _recipient)
        external
    {
        _submit(_courseId, _solution, _recipient);
    }

    // -------------------------------------------------------------------------
    // `owner`-only functions
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    function addCourse(ICourse _course) external onlyOwner {
        // Revert if `_course` is the zero address.
        if (address(_course) == address(0)) revert AddressIsZeroAddress();

        unchecked {
            uint32 curCourseId = ++courseId;

            // Add the course.
            getCourse[curCourseId] =
                CourseData({ course: _course, gasUsed: 0, solutionCount: 0, kingCount: 0 });

            // Emit event.
            emit AddCourse(curCourseId, ICourse(msg.sender));
        }
    }

    /// @inheritdoc ICurtaGolf
    function setPurityChecker(IPurityChecker _purityChecker) external onlyOwner {
        // Revert if `_purityChecker` is the zero address.
        if (address(_purityChecker) == address(0)) revert AddressIsZeroAddress();

        // Set purity checker.
        purityChecker = _purityChecker;

        // Emit event.
        emit SetPurityChecker(_purityChecker);
    }

    // -------------------------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------------------------

    /// @notice Submits a solution by revealing a previously committed solution.
    /// @param _courseId The ID of the course.
    /// @param _solution The bytecode of the solution.
    /// @param _recipient The address of the recipient.
    function _submit(uint32 _courseId, bytes memory _solution, address _recipient) internal {
        CourseData memory courseData = getCourse[_courseId];

        // Revert if the course does not exist.
        if (address(courseData.course) == address(0)) revert CourseDoesNotExist(_courseId);

        // Revert if the solution contains invalid opcodes.
        if (!purityChecker.check(_solution)) revert PollutedSolution();

        // Deploy the solution.
        address target;
        assembly {
            target := create(0, add(_solution, 0x20), mload(_solution))
        }

        // Run solution and mint NFT if it beats the leading score.
        uint32 gasUsed = courseData.course.run(target, block.prevrandao);
        if (courseData.gasUsed == 0 || gasUsed < courseData.gasUsed) {
            // Update course's leading score.
            courseData.gasUsed = gasUsed;

            // Mint or force transfer NFT to `_recipient`.
            if (_ownerOf[_courseId] == address(0)) {
                _mint(_recipient, _courseId);
            } else {
                _forceTransfer(_recipient, _courseId);
            }

            // Increment King count.
            unchecked {
                courseData.kingCount++;
            }

            // Emit event.
            emit UpdateKing(_courseId, _recipient, gasUsed);
        }

        // Increment solution count.
        unchecked {
            courseData.solutionCount++;
        }

        // Update storage.
        getCourse[_courseId] = courseData;

        // Upmint a token to `_recipient` in the Par contract.
        par.upmint(_recipient, _courseId, gasUsed);

        // Emit event.
        emit SubmitSolution(_courseId, _recipient, target);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc KingERC721
    function tokenURI(uint256 _id) public view override returns (string memory) {
        return "TODO";
    }
}
