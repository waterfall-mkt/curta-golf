// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";
import { Owned } from "solmate/auth/Owned.sol";

import { Par } from "./Par.sol";
import { ICourse } from "./interfaces/ICourse.sol";
import { ICurtaGolf } from "./interfaces/ICurtaGolf.sol";
import { IPurityChecker } from "./interfaces/IPurityChecker.sol";
import { KingERC721 } from "./tokens/KingERC721.sol";
import { KingArt } from "./utils/metadata/KingArt.sol";

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
    using LibString for uint256;

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

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    uint32 public override courseId;

    /// @inheritdoc ICurtaGolf
    IPurityChecker public override purityChecker;

    /// @inheritdoc ICurtaGolf
    mapping(uint32 courseId => uint256 getAllowedOpcodes) public override getAllowedOpcodes;

    /// @inheritdoc ICurtaGolf
    mapping(bytes32 key => Commit commit) public override getCommit;

    /// @inheritdoc ICurtaGolf
    mapping(uint32 courseId => CourseData courseData) public override getCourse;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _par The Par contract.
    /// @param _purityChecker The purity checker contract.
    constructor(Par _par, IPurityChecker _purityChecker)
        KingERC721("Curta Golf", "KING")
        Owned(msg.sender)
    {
        par = _par;
        purityChecker = _purityChecker;

        // Emit event.
        emit SetPurityChecker(_purityChecker);
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

        // Emit event.
        emit CommitSolution(msg.sender, _key);
    }

    /// @inheritdoc ICurtaGolf
    function submit(uint32 _courseId, bytes memory _solution, address _recipient, uint256 _salt)
        external
        returns (uint32)
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

        return _submit(_courseId, _solution, _recipient);
    }

    // -------------------------------------------------------------------------
    // `owner`-only functions
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    function addCourse(ICourse _course, uint256 _allowedOpcodes) external onlyOwner {
        // Revert if `_course` is the zero address.
        if (address(_course) == address(0)) revert AddressIsZeroAddress();

        unchecked {
            uint32 curCourseId = ++courseId;

            // Set allowed opcodes for the course.
            getAllowedOpcodes[curCourseId] = _allowedOpcodes;

            // Add the course.
            getCourse[curCourseId] =
                CourseData({ course: _course, gasUsed: 0, solutionCount: 0, kingCount: 0 });

            // Emit events.
            emit SetAllowedOpcodes(curCourseId, _allowedOpcodes);
            emit AddCourse(curCourseId, _course);
        }
    }

    /// @inheritdoc ICurtaGolf
    function setAllowedOpcodes(uint32 _courseId, uint256 _allowedOpcodes) external onlyOwner {
        // Revert if the course does not exist.
        if (address(getCourse[_courseId].course) == address(0)) {
            revert CourseDoesNotExist(_courseId);
        }

        // Set allowed opcodes for the course.
        getAllowedOpcodes[_courseId] = _allowedOpcodes;

        // Emit event.
        emit SetAllowedOpcodes(_courseId, _allowedOpcodes);
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
    /// @return The gas used by the solution.
    function _submit(uint32 _courseId, bytes memory _solution, address _recipient)
        internal
        returns (uint32)
    {
        CourseData memory courseData = getCourse[_courseId];

        // Revert if the course does not exist.
        if (address(courseData.course) == address(0)) revert CourseDoesNotExist(_courseId);

        // Revert if the initcode contains invalid opcodes.
        if (!purityChecker.check(_solution, getAllowedOpcodes[_courseId])) {
            revert PollutedSolution();
        }

        // Deploy the solution.
        address target;
        assembly {
            target := create(0, add(_solution, 0x20), mload(_solution))
        }

        // Revert if the runtime contains invalid opcodes.
        if (!purityChecker.check(target.code, getAllowedOpcodes[_courseId])) {
            revert PollutedSolution();
        }

        // Run solution and mint NFT if it beats the leading score.
        uint32 gasUsed = courseData.course.run(target, block.prevrandao);
        if (courseData.gasUsed == 0 || gasUsed < courseData.gasUsed) {
            // Update course's leading score.
            courseData.gasUsed = gasUsed;

            // Mint or force transfer NFT to `_recipient`.
            if (_tokenData[_courseId].owner == address(0)) {
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
        emit SubmitSolution(_courseId, _recipient, target, gasUsed);

        // Return gas used.
        return gasUsed;
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc KingERC721
    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(_tokenData[_id].owner != address(0), "NOT_MINTED");

        CourseData memory courseData = getCourse[uint32(_id)];

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Curta Golf King #',
                    _id.toString(),
                    " - ",
                    courseData.course.name(),
                    '","description":"This token represents the gas-golfing \\"'
                    'King of the Hill\\" to Curta Golf Course #',
                    _id.toString(),
                    '.","image_data": "data:image/svg+xml;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            KingArt.render({
                                _id: _id,
                                _metadata: _tokenData[_id].metadata,
                                _solves: courseData.solutionCount,
                                _gasUsed: courseData.gasUsed
                            })
                        )
                    ),
                    '"}'
                )
            )
        );
    }
}
