// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { BaseTest } from "./utils/BaseTest.sol";

contract PurityCheckerTest is BaseTest {

    /// @notice Opcodes allowed for the `MockCourse`.
    /// Impure opcode table from: https://blog.sigmaprime.io/evm-purity.html
    /// ________________________________________________________________________
    /// | 0x30 | ADDRESS
    /// | 0x31 | BALANCE
    /// | 0x32 | ORIGIN
    /// | 0x33 | CALLER
    /// | 0x3a | GASPRICE
    /// | 0x3b | EXTCODESIZE
    /// | 0x3c | EXTCODECOPY
    /// | 0x40 | BLOCKHASH
    /// | 0x41 | COINBASE
    /// | 0x42 | TIMESTAMP
    /// | 0x43 | NUMBER
    /// | 0x44 | DIFFICULTY
    /// | 0x45 | GASLIMIT
    /// | 0x54 | SLOAD
    /// | 0x55 | SSTORE
    /// | 0xf0 | CREATE
    /// | 0xf1 | CALL
    /// | 0xf2 | CALLCODE
    /// | 0xf4 | DELEGATECALL
    /// | 0xf5 | CREATE2
    /// | 0xfa | STATICCALL
    /// | 0xff | SELFDESTRUCT
    /// |_______________________________________________________________________
    uint256 internal immutable opcodeBitmap =
        generateBitmap(hex"000102030405060708090a0b_101112131415161718191a1b1c1d_20_303132333435363738393a3d3e_404142434445464748_5051525354565758595a5b_5f606162636465666768696a6b6c6d6e6f_707172737475767778797a7b7c7d7e7f_808182838485868788898a8b8c8d8e8f_909192939495969798999a9b9c9d9e9f_f3fdfe");

    /// @notice For this test we will set the `allowedOpcodes` for the first 
    /// course to the value of `opcodeBitmap` so we can test with some bits
    /// set to 0.
    function setUp() public override {
        super.setUp();
        vm.prank(curtaGolf.owner());
        curtaGolf.setAllowedOpcodes(1, opcodeBitmap);
    }

    function test_bitmask() public {
        assertEq(generateBitmap(hex"000106"), 67);
        assertEq(generateBitmap(hex"0001020304050607"), 255);
        assertEq(generateBitmap(hex"0001"), 3);
    }

    /// @notice Tests that the purity checker correctly checks the bytecode
    /// against all disallowed opcodes set in `setUp()`
    function test_check() public {
        // Test against a few allowed opcodes.
        assertTrue(purityChecker.check(hex"00", opcodeBitmap));
        assertTrue(purityChecker.check(hex"20", opcodeBitmap));
        assertTrue(purityChecker.check(hex"5f", opcodeBitmap));
        assertTrue(purityChecker.check(hex"60", opcodeBitmap));
        assertTrue(purityChecker.check(hex"f3", opcodeBitmap));
        assertTrue(purityChecker.check(hex"fd", opcodeBitmap));
        assertTrue(purityChecker.check(hex"fe", opcodeBitmap));

        // Test against all disallowed opcodes.
        assertFalse(purityChecker.check(hex"3b", opcodeBitmap));
        assertFalse(purityChecker.check(hex"3c", opcodeBitmap));
        assertFalse(purityChecker.check(hex"55", opcodeBitmap));
        assertFalse(purityChecker.check(hex"f0", opcodeBitmap));
        assertFalse(purityChecker.check(hex"f1", opcodeBitmap));
        assertFalse(purityChecker.check(hex"f2", opcodeBitmap));
        assertFalse(purityChecker.check(hex"f4", opcodeBitmap));
        assertFalse(purityChecker.check(hex"f5", opcodeBitmap));
        assertFalse(purityChecker.check(hex"fa", opcodeBitmap));
        assertFalse(purityChecker.check(hex"ff", opcodeBitmap));
    }

    /// @notice Creates a custom bitmap and tests that the purity checker
    /// correctly checks the bytecode against the bitmap.
    function test_customBitmap() public {
        // Here we allow opcodes 0x00, 0x20, and 0xFE.
        uint256 bitmap = generateBitmap(hex"00_20_fe");
        assertEq(bitmap, 28948022309329048855892746252171976963317496166410141009864396001982577377281);
        assertTrue(purityChecker.check(hex"", bitmap));
        assertTrue(purityChecker.check(hex"00", bitmap));
        assertTrue(purityChecker.check(hex"20", bitmap));
        assertTrue(purityChecker.check(hex"20fe0020fefe", bitmap));
        assertFalse(purityChecker.check(hex"ff", bitmap));
    }

    function generateBitmap(bytes memory allowedOpcodes) public pure returns (uint256 bitmap) {
        for (uint256 i = 0; i < allowedOpcodes.length; i++) {
            bitmap |= 1 << uint8(allowedOpcodes[i]);
        }
    }
}