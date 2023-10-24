// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";

abstract contract CurtaGolfERC721 is ERC721TokenReceiver {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
}
