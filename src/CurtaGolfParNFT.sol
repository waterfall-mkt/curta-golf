// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721 } from "solmate/tokens/ERC721.sol";

/// @title The Curta Golf ``Par'' ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice ``Par'' tokens are ERC-721 tokens awarded to any successful solve on
/// any Curta Golf course (i.e. challenge).
abstract contract CurtaGolfParNFT is ERC721 {
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
    // Storage
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Constructor + mint function
    // -------------------------------------------------------------------------

    /// @param _curtaGolf The Curta Golf contract.
    constructor(address _curtaGolf) ERC721("Curta Golf Par", "PAR") {
        curtaGolf = _curtaGolf;
    }

    /// @notice Mints a token to `_to`.
    /// @dev Only the Curta Golf contract can call this function.
    /// @param _courseId The ID of the course to mint the token for.
    /// @param _to The address to mint the token to.
    function mint(uint32 _courseId, address _to) external {
        // Revert if the sender is not the Curta Golf contract.
        if (msg.sender != curtaGolf) revert Unauthorized();

        _mint(_to, (_courseId << 160) | uint256(uint160(_to)));
    }
}
