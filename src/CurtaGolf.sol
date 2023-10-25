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
    function tokenURI(uint256 _id) external view override returns (string memory) {
        return "TODO";
    }
}
