// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Owned } from "solmate/auth/Owned.sol";

import { CurtaGolfPar } from "./CurtaGolfPar.sol";
import { ICourse } from "./interfaces/ICourse.sol";
import { ICurtaGolf } from "./interfaces/ICurtaGolf.sol";
import { IPurityChecker } from "./interfaces/IPurityChecker.sol";
import { CurtaGolfERC721 } from "./tokens/CurtaGolfERC721.sol";

contract CurtaGolf is ICurtaGolf, CurtaGolfERC721, Owned {
    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @inheritdoc ICurtaGolf
    CurtaGolfPar public immutable override curtaGolfPar;

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

    /// @param _curtaGolfPar The Curta Golf Par contract.
    /// @param _renderer The address of the renderer used to render tokens'
    /// metadata.
    constructor(CurtaGolfPar _curtaGolfPar, address _renderer)
        CurtaGolfERC721("Curta Golf", "KING")
        Owned(msg.sender)
    {
        curtaGolfPar = _curtaGolfPar;
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
        getCommit[_key] = Commit({ player: msg.sender, blockNumber: uint96(block.number) });
    }

    /// @inheritdoc ICurtaGolf
    function submit(uint32 _courseId, bytes memory _solution, address _recipient, uint256 _salt)
        external
    {
        CourseData memory courseData = getCourse[_courseId];

        // Revert if the course does not exist.
        if (address(courseData.course) == address(0)) revert CourseDoesNotExist(_courseId);

        // Compute key.
        bytes32 key = keccak256(abi.encode(msg.sender, _solution, _salt));

        // Revert if the corresponding commit was never made.
        if (getCommit[key].player == address(0)) revert KeyNotCommitted(key);

        // Revert if the solution contains invalid opcodes.
        if (!purityChecker.check(_solution)) revert PollutedSolution();

        // Deploy the solution.
        address target;
        assembly {
            target := create(0, add(_solution, 0x20), mload(_solution))
        }

        // Run user solution and mint NFT if it beats the leading score.
        uint32 gasUsed = courseData.course.run(target, block.prevrandao);
        if (courseData.gasUsed == 0 || gasUsed < courseData.gasUsed) {
            // Update course's leading score.
            getCourse[_courseId].gasUsed = gasUsed;

            // TODO: Force transfer NFT to `_recipient` and emit event.
        }
    }

    /// @inheritdoc ICurtaGolf
    function submitDirectly(uint32 _courseId, bytes memory _solution, address _recipient)
        external
    { }

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
            getCourse[curCourseId] = CourseData({ course: _course, gasUsed: 0 });

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
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc CurtaGolfERC721
    function tokenURI(uint256 _id) public view override returns (string memory) {
        return "TODO";
    }
}
