// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Owned } from "solmate/auth/Owned.sol";

import { CurtaGolfPar } from "./CurtaGolfPar.sol";
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
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc CurtaGolfERC721
    function tokenURI(uint256 _id) external view override returns (string memory) {
        return "TODO";
    }
}
