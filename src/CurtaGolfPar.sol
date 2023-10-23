// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { CurtaGolfParERC721 } from "./tokens/CurtaGolfParERC721.sol";

/// @title The Curta Golf ``Par'' NFT contract
/// @author fiveoutofnine
/// @notice ``Par'' tokens are ERC-721 tokens awarded to any successful solve on
/// any Curta Golf course (i.e. challenge).
/// @dev Only the Curta Golf contract can mint Par tokens. To ensure a maximum
/// of 1 token per (course, solver) pair, tokens are addressed by its
/// corresponding course ID and solver address, i.e. the token IDs are minted
/// as `(_courseId << 160) | _recipient`. Upon a successful submission, if the
/// solver already has a token for the course, the token is updated with the
/// new gas used if the new gas used is less than the old gas used.
contract CurtaGolfPar is CurtaGolfParERC721 {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice The Curta Golf contract.
    address public immutable curtaGolf;

    // -------------------------------------------------------------------------
    // Constructor + mint function
    // -------------------------------------------------------------------------

    /// @param _curtaGolf The Curta Golf contract.
    constructor(address _curtaGolf) CurtaGolfParERC721("Curta Golf Par", "PAR") {
        curtaGolf = _curtaGolf;
    }

    /// @notice Mints a token to `_to` or updates the gas used on the token if
    /// it already exists and `_gasUsed` is less than `_to`'s current leading
    /// solution.
    /// @dev Only the Curta Golf contract can call this function.
    /// @param _to The address to mint the token to.
    /// @param _courseId The ID of the course to mint the token for.
    /// @param _gasUsed The amount of gas used on the submission.
    function upmint(address _to, uint32 _courseId, uint32 _gasUsed) external {
        // Revert if the sender is not the Curta Golf contract.
        if (msg.sender != curtaGolf) revert Unauthorized();

        // Compute token ID and fetch token data.
        uint256 tokenId = (_courseId << 160) | uint256(uint160(_to));
        CurtaGolfParERC721.TokenData memory tokenData = getTokenData[tokenId];

        // Mint a new token if the token does not exist or update the gas used
        // on the token if the new gas used is less than the current gas used.
        if (tokenData.owner == address(0)) {
            _mint({ _to: _to, _id: tokenId, _gasUsed: _gasUsed });
        } else if (tokenData.gasUsed > _gasUsed) {
            getTokenData[tokenId].gasUsed = _gasUsed;
        }
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc CurtaGolfParERC721
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return "TODO";
    }
}
