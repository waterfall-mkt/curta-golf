// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { KingArt } from "src/utils/metadata/KingArt.sol";

import { BaseTest } from "test/utils/BaseTest.sol";

/// @notice A script to generate and print sample art metadata for Curta King
/// tokens, as outputted by {KingArt}.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
contract PrintKingArtScript is BaseTest, Script {
    function setUp() public override {
        super.setUp();

        // Submit a solution to Course #1 as `fiveoutofnine.eth`.
        curtaGolf.submitDirectly(1, EFFICIENT_SOLUTION, 0xA85572Cd96f1643458f17340b6f0D6549Af482F5);
    }
    // -------------------------------------------------------------------------
    // `run`
    // -------------------------------------------------------------------------

    /// @notice Prints a sample King NFT art generation.
    function run() public view {
        console.log(
            KingArt.render({
                _id: 1,
                _metadata: uint96(uint160(0xA85572Cd96f1643458f17340b6f0D6549Af482F5) >> 64),
                _solves: 112_348_923,
                _gasUsed: 4354
            })
        );

        console.log(curtaGolf.tokenURI(1));
    }
}
