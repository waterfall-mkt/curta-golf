// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721 } from "solmate/tokens/ERC721.sol";

/// @title The Curta Golf ``King'' ERC-721 token contract
/// @author fiveoutofnine
/// @notice An implementation of the ERC-721 standard to allow Curta Golf to
/// forcibly transfer tokens. It will only be used when a course receives a new
/// king (i.e. lowers the previous leading solution's gas usage).
abstract contract CurtaGolfERC721 is ERC721 {
    // -------------------------------------------------------------------------
    // Constructor + `_forceTransfer` function
    // -------------------------------------------------------------------------

    /// @param _name The name of the contract.
    /// @param _symbol An abbreviated name for the contract.
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) { }

    /// @notice Forcibly transfers a token to `_to`, ignoring prior ownership
    /// and approvals.
    /// @dev This function must only be called by the Curta Golf contract when a
    /// course receives a new king (i.e. lowers the previous leading solution's
    /// gas usage).
    /// @param _to The address to transfer the token to.
    /// @param _id The ID of the token to transfer.
    function _forceTransfer(address _to, uint256 _id) internal {
        require(_to != address(0), "INVALID_RECIPIENT");
        address from = _ownerOf[_id];
        // Better have this than try to save gas...
        require(from != address(0), "NOT_MINTED");

        // Update balances.
        unchecked {
            // Will never underflow because of the token ownership check above.
            _balanceOf[from]--;
            // Will never overflow because the recipient's balance can't
            // realistically overflow.
            _balanceOf[_to]++;
        }

        // Set new owner.
        _ownerOf[_id] = _to;

        // Clear previous approval data for the token.
        delete getApproved[_id];

        // Emit event.
        emit Transfer(from, _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _id The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _id) public view virtual override returns (string memory);
}
