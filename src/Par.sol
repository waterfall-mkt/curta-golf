// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721, ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

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
contract Par is ERC721("Par", "PAR"), ERC721TokenReceiver {
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
    // Structs
    // -------------------------------------------------------------------------

    /// @param owner The owner of the token.
    /// @param gasUsed The amount of gas used on the owner's leading solution
    /// for the corresponding course.
    struct TokenData {
        address owner;
        uint32 gasUsed;
    }

    // -------------------------------------------------------------------------
    // ERC721 storage (+ custom)
    // -------------------------------------------------------------------------


    mapping(uint256 => TokenData) internal _tokenData;

    // -------------------------------------------------------------------------
    // Constructor + `_mint` function
    // -------------------------------------------------------------------------

    /// @param _curtaGolf The Curta Golf contract.
    constructor(address _curtaGolf) {
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
        ParERC721.TokenData memory tokenData = _tokenData[tokenId];

        // Mint a new token if the token does not exist or update the gas used
        // on the token if the new gas used is less than the current gas used.
        if (tokenData.owner == address(0)) {
            _mint({ _to: _to, _id: tokenId, _gasUsed: _gasUsed });
        } else if (tokenData.gasUsed > _gasUsed) {
            _tokenData[tokenId].gasUsed = _gasUsed;
        }
    }

    /// @notice Mints a Par token to `_to`.
    /// @dev This function can only called by {CurtaGolf}, so it makes a few
    /// assumptions. For example, the ID of the token is always in the form
    /// `(courseId << 160) | _to`, and the token is never minted to the zero
    /// address.
    /// @param _to The address to mint the token to.
    /// @param _id The ID of the token.
    /// @param _gasUsed The amount of gas used on the owner's leading solution
    /// for the corresponding course.
    function _mint(address _to, uint256 _id, uint32 _gasUsed) internal {
        // Update balances.
        unchecked {
            // Will never overflow because the recipient's balance can't
            // realistically overflow.
            _balanceOf[_to]++;
        }

        // Set new owner
        _tokenData[_id] = TokenData({ owner: _to, gasUsed: _gasUsed });

        // Emit event.
        emit Transfer(address(0), _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721 functions
    // -------------------------------------------------------------------------

    function approve(address _spender, uint256 _id) public override {
        address owner = _tokenData[_id].owner;

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        // Set the spender as approved for the token.
        getApproved[_id] = _spender;

        // Emit event.
        emit Approval(owner, _spender, _id);
    }

    function ownerOf(uint256 _id) public view override returns (address owner) {
        require((owner = _tokenData[_id].owner) != address(0), "NOT_MINTED");
    }

    function transferFrom(address _from, address _to, uint256 _id) public override {
        // Revert if the token is not being transferred from the current owner.
        require(_from == _tokenData[_id].owner, "WRONG_FROM");

        // Revert if the recipient is the zero address.
        require(_to != address(0), "INVALID_RECIPIENT");

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender]
                || msg.sender == getApproved[_id],
            "NOT_AUTHORIZED"
        );

        // Update balances.
        unchecked {
            // Will never underflow because of the token ownership check above.
            _balanceOf[_from]--;
            // Will never overflow because the recipient's balance can't
            // realistically overflow.
            _balanceOf[_to]++;
        }

        // Set new owner.
        _tokenData[_id].owner = _to;

        // Clear previous approval data for the token.
        delete getApproved[_id];

        // Emit event.
        emit Transfer(_from, _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _id The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _id) public view override returns (string memory) {
        return "TODO";
    }

    // -------------------------------------------------------------------------
    // Read functions
    // -------------------------------------------------------------------------

    /// @notice Returns the token data for the token with ID `_id` if the token
    /// exists.
    /// @param _id The ID of the token.
    /// @return tokenData The token data.
    function getTokenData(uint256 _id) external view returns (TokenData memory tokenData) {
        require((tokenData = _tokenData[_id]).owner != address(0), "NOT_MINTED");
    }
}
