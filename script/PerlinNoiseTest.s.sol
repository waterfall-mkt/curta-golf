// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { Perlin } from "src/utils/Perlin.sol";

/// @notice A test/scratchwork script to generate and print an ASCII
/// representation for Curta King token art metadata.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
contract PerlinNoiseTestScript is Script {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The maximum value of a `x`/`y` coordinate for Perlin noise.
    uint256 constant MAX = 1 << 31;

    /// @notice The number of tiles wide the map is.
    /// @dev Changing this from `12` may break the script.
    uint256 constant WIDTH = 12;

    /// @notice The number of tiles tall the map is.
    /// @dev Changing this from `17` may break the script.
    uint256 constant HEIGHT = 17;

    /// @notice The seed used to generate the map.
    uint32 SEED = 2;

    // -------------------------------------------------------------------------
    // `run`
    // -------------------------------------------------------------------------

    /// @notice Prints an ASCII representation of a 17 × 12 hexagonal tile map
    /// generated using Perlin noise.
    function run() public view {
        unchecked {
            uint256[HEIGHT][WIDTH] memory perlin1;
            uint256[HEIGHT][WIDTH] memory perlin2;
            uint32 seed1 = SEED;
            uint32 seed2 = SEED + 1;
            (uint256 min1, uint256 max1) = (MAX, 0);
            (uint256 min2, uint256 max2) = (MAX, 0);

            // Loop through each tile coordinate and generate the Perlin noise value
            // at that coordinate for each of the two seeds.
            for (uint256 col; col < WIDTH; ++col) {
                for (uint256 row; row < HEIGHT; ++row) {
                    uint32 x = uint32(col * MAX / WIDTH);
                    uint32 y = uint32(row * MAX / HEIGHT);

                    // Generate the Perlin nose values at each tile coordinate.
                    uint256 noise1 = _noise(x, y, seed1);
                    uint256 noise2 = _noise(x, y, seed2);
                    perlin1[col][row] = noise1;
                    perlin2[col][row] = noise2;

                    // Keep track of the minimum and maximum values within each
                    // 2d-array of generated Perlin noise values to normalize them
                    // later.
                    if (noise1 < min1) min1 = noise1;
                    if (noise1 > max1) max1 = noise1;
                    if (noise2 < min2) min2 = noise2;
                    if (noise2 > max2) max2 = noise2;
                }
            }

            // Compute the range of values within each 2d-array for normalization.
            uint256 range1 = max1 - min1;
            range1 = range1 == 0 ? 1 : range1; // Avoid division by zero.
            uint256 range2 = max2 - min2;
            range2 = range2 == 0 ? 1 : range2; // Avoid division by zero.

            // Select the tiles depending on `perlin1` and `perlin2` and generate
            // the ASCII string.
            string memory ascii_map = "";
            for (uint256 row; row < HEIGHT; ++row) {
                string memory ascii_row = "";
                for (uint256 col; col < WIDTH; ++col) {
                    // Normalize the Perlin noise values to the range [0, 60].
                    uint256 temperature = 60 * (perlin1[col][row] - min1) / range1;
                    uint256 rainfall = 60 * (perlin2[col][row] - min2) / range2;

                    // Select the tile based on the temperature and rainfall.
                    string memory tile = "";
                    if (rainfall < 12) {
                        tile = "@"; // Rainforest
                    } else if (rainfall < 24) {
                        if (temperature < 30) tile = "@"; // Rainforest

                        else tile = "*"; // Wetland
                    } else if (rainfall < 36) {
                        if (temperature < 20) tile = "%"; // Temperate forest

                        else if (temperature < 40) tile = "#"; // Boreal forest

                        else tile = "+"; // Marsh
                    } else if (rainfall < 48) {
                        if (temperature < 30) tile = ":"; // Plains

                        else tile = "="; // Grassland
                    } else {
                        if (temperature < 15) tile = "-"; // Desert

                        else if (temperature < 30) tile = ":"; // Plains

                        else if (temperature < 45) tile = "."; // Tundra

                        else tile = "_"; // Snow
                    }

                    // Exclude the tile (i.e. print as ` `) if it is not part of the
                    // island's shape. We determine whether a tile at a given
                    // `(row, col)` is part of the island via a bitmap, where a `1`
                    // at the LSb position equal to `12 * row + col` indicates the
                    // tile is part of the island. i.e. the bitmap below are the
                    // following bits concatenated together:
                    // ```
                    // 000111111000
                    // 000111111100
                    // 001111111100
                    // 001111111110
                    // 011111111110
                    // 001111111111
                    // 111111111111
                    // 001111111111
                    // 111111111111
                    // 001111111111
                    // 111111111111
                    // 001111111111
                    // 011111111110
                    // 001111111110
                    // 001111111100
                    // 000111111100
                    // 000111111000
                    // ```
                    if (
                        (0x1f81fc3fc3fe7fe3fffff3fffff3fffff3ff7fe3fe3fc1fc1f8 >> (12 * row + col))
                            & 1 == 0
                    ) tile = " ";
                    ascii_row = string.concat(ascii_row, tile, "   ");
                }
                // Append the row to the map, prepended with a ` ` if the row is
                // odd-numbered.
                ascii_map = string.concat(ascii_map, row & 1 == 1 ? "  " : "", ascii_row, "\n");
            }

            // Log the map.
            console.log(ascii_map);
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /// @notice A helper function to interact with the {Perlin} library.
    /// @dev This function is abstracted in case we want to play around with
    /// the `scale` parameter or perform additional transformations on the
    /// noise value.
    /// @param _x The `x` coordinate.
    /// @param _y The `y` coordinate.
    /// @param _seed The seed used to generate the noise.
    /// @return The noise value at (`_x`, `_y`).
    function _noise(uint32 _x, uint32 _y, uint32 _seed) internal pure returns (uint256) {
        return Perlin.computePerlin(_x, _y, _seed, 10);
    }
}
