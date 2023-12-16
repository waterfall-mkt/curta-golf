// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { BaseTest } from "test/utils/BaseTest.sol";

/// @notice A script to generate and print sample art metadata for Curta King
/// tokens, as outputted by {KingArt}.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
contract PrintParArtScript is BaseTest, Script {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The address of the recipient of the solution.
    address constant RECIPIENT = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    function setUp() public override {
        super.setUp();

        // Submit a solution to course #1 as `RECIPIENT`.
        curtaGolf.submitDirectly(1, EFFICIENT_SOLUTION, RECIPIENT);
    }
    // -------------------------------------------------------------------------
    // `run`
    // -------------------------------------------------------------------------

    /// @notice Prints a sample King NFT art generation.
    function run() public view {
        console.log(par.tokenURI((1 << 160) | uint256(uint160(RECIPIENT))));
    }
}
