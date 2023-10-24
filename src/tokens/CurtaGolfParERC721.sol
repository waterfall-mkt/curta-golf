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
abstract contract CurtaGolfParERC721 is ERC721TokenReceiver {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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

    mapping(address => uint256) internal _balanceOf;

    mapping(uint256 => TokenData) internal _tokenData;

    mapping(uint256 => address) public getApproved;

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
    /// `(courseId << 160) | _to`.
    /// @param _to The address to mint the token to.
    /// @param _id The ID of the token.
    /// @param _gasUsed The amount of gas used on the owner's leading solution
    /// for the corresponding course.
    function _mint(address _to, uint256 _id, uint32 _gasUsed) internal {
        // We do not check whether the `_to` is `address(0)` or that the token
        // was previously minted because {CurtaGolf} ensures these conditions
        // are never true.

        unchecked {
            ++_balanceOf[_to];
        }

        _tokenData[_id] = TokenData({ owner: _to, gasUsed: _gasUsed });

        // Emit event.
        emit Transfer(address(0), _to, _id);
    }

    // -------------------------------------------------------------------------
    // ERC721 functions
    // -------------------------------------------------------------------------

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

    function setApprovalForAll(address _operator, bool _approved) external {
        // Set the operator as approved for the sender.
        isApprovedForAll[msg.sender][_operator] = _approved;

        // Emit event.
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    function ownerOf(uint256 _id) public view returns (address owner) {
        require((owner = _tokenData[_id].owner) != address(0), "NOT_MINTED");
    }

    function transferFrom(address _from, address _to, uint256 _id) public virtual {
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

            _balanceOf[_to]++;
        }

        // Set new owner.
        _tokenData[_id].owner = _to;

        // Clear previous approval data for the token.
        delete getApproved[_id];

        // Emit event.
        emit Transfer(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        transferFrom(_from, _to, _id);

        require(
            _to.code.length == 0
                || ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

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
    /// @return tokenData The token data.
    function getTokenData(uint256 _id) external view returns (TokenData memory tokenData) {
        require((tokenData = _tokenData[_id]).owner != address(0), "NOT_MINTED");
    }
}
