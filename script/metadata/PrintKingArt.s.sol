// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { KingArt } from "src/utils/metadata/KingArt.sol";

/// @notice A script to generate and print sample art metadata for Curta King
/// tokens, as outputted by {KingArt}.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
contract PrintKingArtScript is Script {
    // -------------------------------------------------------------------------
    // `run`
    // -------------------------------------------------------------------------

    /// @notice Prints a sample King NFT art generation.
    function run() public view {
        console.log(KingArt.render(1));
    }
}
