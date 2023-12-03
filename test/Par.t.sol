// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Par } from "../src/Par.sol";
import { BaseTest } from "./utils/BaseTest.sol";

/// @notice Unit tests for `Par`, organized by functions.
contract ParTest is BaseTest {
    // -------------------------------------------------------------------------
    // `curtaGolf`
    // -------------------------------------------------------------------------

    /// @notice Test that `curtaGolf` was set correctly in the constructor.
    function test_curtaGolf_Equality() public {
        assertEq(par.curtaGolf(), address(curtaGolf));
    }

    // -------------------------------------------------------------------------
    // `upmint`
    // -------------------------------------------------------------------------

    /// @notice Test that calling `upmint` from an address that's not
    /// `curtaGolf` reverts.
    /// @param _sender The address to call `upmint` from.
    function test_upmint_NotCurtaGolf_Unauthorized(address _sender) public {
        vm.assume(_sender != par.curtaGolf());

        vm.expectRevert(Par.Unauthorized.selector);
        par.upmint(address(this), 0, 0);
    }

    /// @notice Test that upminting a token with a new, higher gas used record
    /// on a minted token does not update the token's `gasUsed` field.
    function test_upmint_ExistingTokenDoesntBeatRecord_DoesntUpdateStorage() public {
        // Mint a token to `solver1` with a gas used of `21_500` on course 1.
        vm.prank(par.curtaGolf());
        par.upmint(solver1, 1, 21_500);
        uint256 tokenId = (1 << 160) | uint256(uint160(solver1));

        // Check that the token exists and has the correct gas used.
        {
            Par.TokenData memory tokenData = par.getTokenData(tokenId);
            assertEq(tokenData.owner, solver1);
            assertEq(tokenData.gasUsed, 21_500);
            assertEq(par.balanceOf(solver1), 1);
        }

        // Upmint the token to `solver1` with a value higher than `22_500` on
        // course 1.
        vm.prank(par.curtaGolf());
        par.upmint(solver1, 1, 22_500);

        // Check that the token's `gasUsed` was not updated.
        {
            Par.TokenData memory tokenData = par.getTokenData(tokenId);
            assertEq(tokenData.owner, solver1);
            assertEq(tokenData.gasUsed, 21_500);
            assertEq(par.balanceOf(solver1), 1);
        }
    }

    /// @notice Test that upminting a token with a new, lower gas used record
    /// on a minted token updates the token's `gasUsed` field.
    function test_upmint_ExistingTokenBeatsRecord_UpdatesStorage() public {
        // Mint a token to `solver1` with a gas used of `21_500` on course 1.
        vm.prank(par.curtaGolf());
        par.upmint(solver1, 1, 21_500);
        uint256 tokenId = (1 << 160) | uint256(uint160(solver1));

        // Check that the token exists and has the correct gas used.
        {
            Par.TokenData memory tokenData = par.getTokenData(tokenId);
            assertEq(tokenData.owner, solver1);
            assertEq(tokenData.gasUsed, 21_500);
            assertEq(par.balanceOf(solver1), 1);
        }

        // Upmint the token to `solver1` with a value lower than `21_500` on
        // course 1.
        vm.prank(par.curtaGolf());
        par.upmint(solver1, 1, 21_000);

        // Check that the token's `gasUsed` was updated.
        {
            Par.TokenData memory tokenData = par.getTokenData(tokenId);
            assertEq(tokenData.owner, solver1);
            assertEq(tokenData.gasUsed, 21_000);
            assertEq(par.balanceOf(solver1), 1);
        }
    }

    /// @notice Test events emitted and storage updates upon upminting a
    /// new token.
    function test_upmint(address _to, uint32 _courseId, uint32 _gasUsed) public {
        vm.assume(_to != address(0));

        // Check that the token doesn't exist.
        uint256 tokenId = (uint256(_courseId) << 160) | uint256(uint160(_to));
        vm.expectRevert("NOT_MINTED");
        par.getTokenData(tokenId);
        // Check that `_to` has 0 tokens.
        assertEq(par.balanceOf(_to), 0);

        // Upmint the token.
        vm.prank(par.curtaGolf());
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), _to, tokenId);
        par.upmint(_to, _courseId, _gasUsed);

        // Check that the token was minted with the correct `owner` and
        // `gasUsed`.
        {
            Par.TokenData memory tokenData = par.getTokenData(tokenId);
            assertEq(tokenData.owner, _to);
            assertEq(tokenData.gasUsed, _gasUsed);
        }
        // Check that `_to` has 1 token.
        assertEq(par.balanceOf(_to), 1);
    }

    // -------------------------------------------------------------------------
    // `tokenURI`
    // -------------------------------------------------------------------------

    /// @notice Test that calling `tokenURI` on an unminted token reverts.
    function test_tokenURI_UnmintedToken_Reverts() public {
        vm.expectRevert("NOT_MINTED");
        par.tokenURI(0);
    }

    /// @notice Test that calling `tokenURI` on a minted token succeeds.
    function test_tokenURI_MintedToken_Succeeds() public {
        // Prank as `curtaGolf` and mint a token to `solver1`.
        vm.prank(par.curtaGolf());
        par.upmint(solver1, 1, 21_500);

        par.tokenURI((1 << 160) | uint256(uint160(solver1)));
    }
}
