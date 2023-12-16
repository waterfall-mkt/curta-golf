// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

/// @title The Curta Golf ``Par'' ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice A custom implementation of the ERC-721 standard to efficiently keep
/// track of players' leading solutions (i.e. least gas used) for each course.
/// The mint function packs the gas used and the player's address into a single
/// 32-byte slot.
abstract contract ParERC721 {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when the address approved to transfer a token is
    /// updated.
    /// @param owner The owner of the token.
    /// @param spender The address approved to transfer the token.
    /// @param id The ID of the token.
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    /// @notice Emitted when an operator to transfer all of an owner's tokens is
    /// updated.
    /// @param owner The owner of the tokens.
    /// @param operator The address approved to transfer all of the owner's
    /// tokens.
    /// @param approved The new approval status of the operator.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted when a token is transferred.
    /// @param from The address the token is transferred from.
    /// @param to The address the token is transferred to.
    /// @param id The ID of the token.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

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
    // ERC721Metadata storage
    // -------------------------------------------------------------------------

    /// @notice The name of the contract.
    string public name;

    /// @notice An abbreviated name for the contract.
    string public symbol;

    // -------------------------------------------------------------------------
    // ERC721 storage (+ custom)
    // -------------------------------------------------------------------------

    /// @notice A mapping of owners to the number of tokens they own.
    mapping(address => uint256) internal _balanceOf;

    /// @notice A mapping of token IDs to token data, which contains the owner
    /// of the token and the amount of gas used on the owner's leading solution
    /// for the corresponding course
    mapping(uint256 => TokenData) internal _tokenData;

    /// @notice A mapping of token IDs to approved addresses.
    mapping(uint256 => address) public getApproved;

    /// @notice A mapping of owners to operators to approval statuses.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // -------------------------------------------------------------------------
    // Constructor + `_mint` function
    // -------------------------------------------------------------------------

    /// @param _name The name of the contract.
    /// @param _symbol An abbreviated name for the contract.
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
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

    /// @notice Returns the number of tokens owned by `_owner`.
    /// @param _owner The address to query.
    /// @return The number of tokens owned by `_owner`.
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[_owner];
    }

    /// @notice Returns the owner of the token with ID `_id`.
    /// @param _id The ID of the token.
    /// @return owner The address of the owner of the token.
    function ownerOf(uint256 _id) public view returns (address owner) {
        require((owner = _tokenData[_id].owner) != address(0), "NOT_MINTED");
    }

    /// @notice Approve some address `_spender` to transfer the token with ID
    /// `_id`.
    /// @dev The function reverts if the sender is not the owner or not an
    /// operator for the token.
    /// @param _spender The address to approve.
    /// @param _id The ID of the token to approve.
    function approve(address _spender, uint256 _id) external {
        address owner = _tokenData[_id].owner;

        // Revert if the sender is not the owner, or the owner has not approved
        // the sender to operate the token.
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        // Set the spender as approved for the token.
        getApproved[_id] = _spender;

        // Emit event.
        emit Approval(owner, _spender, _id);
    }

    /// @notice Set the approval for some address `_operator` to transfer all of
    /// the sender's tokens.
    /// @param _operator The address to approve.
    /// @param _approved The new approval status of the operator.
    function setApprovalForAll(address _operator, bool _approved) external {
        // Set the operator as approved for the sender.
        isApprovedForAll[msg.sender][_operator] = _approved;

        // Emit event.
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Transfer the token with ID `_id` from `_from` to `_to`.
    /// @dev The function reverts if the sender is not the owner, not an
    /// operator, not the approved address for the token, not a valid token ID,
    /// or `_to` is not the 0 address and capable of receiving the token (i.e.
    /// implements `onERC721Received`).
    /// @param _from The address to transfer the token from.
    /// @param _to The address to transfer the token to.
    /// @param _id The ID of the token to transfer.
    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice Transfer the token with ID `_id` from `_from` to `_to`.
    /// @dev The function reverts if the sender is not the owner, not an
    /// operator, not the approved address for the token, not a valid token ID,
    /// or `_to` is not the 0 address and capable of receiving the token (i.e.
    /// implements `onERC721Received`).
    /// @param _from The address to transfer the token from.
    /// @param _to The address to transfer the token to.
    /// @param _id The ID of the token to transfer.
    /// @param _data Additional data with no specified format, sent in call to
    /// `_to`.
    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data)
        external
    {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, _data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice Transfer the token with ID `_id` from `_from` to `_to` without
    /// checking if `_to` is capable of receiving the token.
    /// @dev The function reverts if the sender is not the owner, not an
    /// operator, not the approved address for the token, not a valid token ID,
    /// or `_to` is the 0 address.
    /// @param _from The address to transfer the token from.
    /// @param _to The address to transfer the token to.
    /// @param _id The ID of the token to transfer.
    function transferFrom(address _from, address _to, uint256 _id) public {
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
    function tokenURI(uint256 _id) external view virtual returns (string memory);

    // -------------------------------------------------------------------------
    // ERC165
    // -------------------------------------------------------------------------

    /// @notice Checks if the contract supports an interface.
    /// @param _interfaceId The interface identifier, as specified in ERC-165.
    /// @return Whether the contract supports the interface.
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == 0x01FFC9A7 // ERC165 Interface ID for ERC165
            || _interfaceId == 0x80AC58CD // ERC165 Interface ID for ERC721
            || _interfaceId == 0x5B5E139F; // ERC165 Interface ID for ERC721Metadata
    }

    // -------------------------------------------------------------------------
    // Read functions
    // -------------------------------------------------------------------------

    /// @notice Returns the token data for the token with ID `_id` if the token
    /// exists.
    /// @param _id The ID of the token.
    /// @return tokenData A struct containing the owner of the token and the
    /// amount of gas used on the owner's leading solution for the corresponding
    /// course in the shape `{ owner: address, gasUsed: uint32 }`.
    function getTokenData(uint256 _id) external view returns (TokenData memory tokenData) {
        require((tokenData = _tokenData[_id]).owner != address(0), "NOT_MINTED");
    }
}
