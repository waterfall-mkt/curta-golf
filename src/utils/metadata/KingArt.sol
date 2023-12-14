// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { LibString } from "solady/utils/LibString.sol";

import { Perlin } from "src/utils/Perlin.sol";

/// @title Curta Golf King NFT art
/// @notice A library for generating SVGs for {CurtaGolf}.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
/// @author fiveoutofnine
library KingArt {
    using LibString for uint256;

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

    /// @notice Starting string for the island's SVG.
    /// @dev The island's SVG's width and height are computed to perfectly
    /// contain a 12 × 17 hexagonal tile map with 2px of padding because some
    /// tiles overflow the top by 2px.
    ///     * 125 = (12 * 11) - 11 + 2 * 2
    ///         * `12 * 11` is the width (11px) of 12 tiles.
    ///         * `- 11` accounts for the 1px overlap.
    ///         * `+ 2 * 2` accounts for the 2px of padding on either side.
    ///     * 109 = (17 * 9) - (16 * 3) + 2 * 2
    ///         * `17 * 9` is the height (9px) of 17 tiles.
    ///         * `- (16 * 3)` accounts for the 3px of overlap for each row.
    ///         * `+ 2 * 2` accounts for the 2px of padding on either side.
    /// This way, the hexagonal tile is perfectly centered within the SVG, while
    /// leaving leeway for all tiles. The starting string also contains the
    /// following groups of tiles that can be easily and efficiently used via
    /// `<use>`:
    ///                       | ID | Tile             |
    ///                       | -- | ---------------- |
    ///                       | H  | Desert           |
    ///                       | I  | Plains           |
    ///                       | G  | Grassland        |
    ///                       | F  | Hills            |
    ///                       | B  | Wetland          |
    ///                       | J  | Tundra           |
    ///                       | E  | Marsh            |
    ///                       | K  | Snow             |
    ///                       | A  | Rain Forest      |
    ///                       | C  | Temperate Forest |
    ///                       | D  | Boreal Forest    |
    /// Note that the ID values range from `A` to `K`, which corresponds to the
    /// ASCII value range `[0x41, 0x4b]`. We use this fact later to efficiently
    /// compute the tile type at each position. Another important note is that
    /// each tile is defined upside-down. This is because, as mentioned above,
    /// some tiles overflow the top by 2px. Thus, if we defined the tiles
    /// right-side up, we'd have to conditionally compute the tile's
    /// `y`-coordinate offset depending on the tile's type, which would be both
    /// inefficient and difficult to implement. To prevent all this, we simply
    /// define the tiles upside-down, and rotate the entire island by 180°
    /// around the center. This way, the resulting tiles are right-side up, and
    /// we can compute the `x`/`y` coordinates at a given tile position the
    /// same, irregardless of what type the tile is. The only caveat is that, for
    /// parts coming after this string, the `x` and `y` coordinates are
    /// essentially flipped (`(0, 0)` correponds to the bottom right).
    string constant ISLAND_SVG_START =
        '<svg xmlns="http://www.w3.org/2000/svg" width="125" height="109" viewB'
        'ox="0 0 125 109" fill="none"><g visibility="hidden"><g id="z"><path d='
        '"M0 2h11v5H0z"/><path d="M4 0h3v9H4z"/><path d="M2 1h7v1H2zm0 6h7v1H2z'
        '"/></g><g id="y"><path d="M4 0h3v1H4zm0 8h3v1H4zM2 1h2v1H2zm5 0h2v1H7z'
        "M0 2h2v1H0zm9 0h2v1H9zM2 7h2v1H2zm5 0h2v1H7zM0 6h2v1H0zm9 0h2v1H9zM0 3"
        'h1v3H0zm10 0h1v3h-1z"/></g><g id="H"><use href="#z" fill="#e0cd61"/><p'
        'ath d="M4 1h1v1H4zm2 0h1v1H6zm2 1h1v1H8zM3 3h1v1H3zm3 0h1v1H6zM1 4h1v2'
        'H1zm7 0h2v1H8zM4 5h1v1H4zm4 1h1v1H8zM5 7h1v1H5z" fill="#e3d271"/><use '
        'href="#y" fill="#c2b727"/></g><g id="I"><use href="#z" fill="#f2d020"/'
        '><path d="M5 1h2v1H5zM1 3h1v1H1zm2 0h3v1H3zm4 0h3v1H7zM1 5h2v1H1zm3 0h'
        '3v1H4zm4 0h2v2H8zM4 7h2v1H4z" fill="#efd658"/><use href="#y" fill="#d2'
        'b307"/></g><g id="G"><use href="#z" fill="#76c230"/><path d="M5 1h1v1H'
        "5zM2 2h1v2H2zm5 0h1v1H7zM6 3h1v1H6zM5 4h1v1H5zm3 0h2v1H8zM1 5h1v1H1zm3"
        ' 0h1v1H4zm3 0h1v1H7zM5 7h2v1H5z" fill="#7ccd32"/><path d="M3 2h1v1H3zm'
        "5 0h1v1H8zM1 3h1v2H1zm2 2h1v1H3zm3 0h1v1H6zm3 0h1v1H9zM2 6h2v1H2zm3 0h"
        '1v1H5zm3 0h1v1H8z" fill="#71ba2e"/><use href="#y" fill="#46741d"/></g>'
        '<g id="F"><use href="#z" fill="#96ba46"/><use href="#y" fill="#586f2a"'
        '/><path d="M8 2h1v1H8zM7 3h1v1H7zM3 4h1v1H3z" fill="#8fb243"/><path d='
        '"M1 6h9v3H1z" fill="#8fb243"/><path d="M5 1h1v1H5zm2 1h1v1H7zM6 3h1v1H'
        '6zm2 1h1v1H8zM2 6h1v1H2z" fill="#9dc44a"/><path d="M3 2h1v1H3zm3 0h1v1'
        "H6zM1 3h1v1H1zm3 1h1v1H4zm5 0h1v1H9zM1 5h3v1H1zm5 0h2v1H6zM1 6h1v1H1zm"
        '3 1h2v1H4zm4 0h1v1H8zM2 8h1v1H2zm4 0h1v1H6z" fill="#86a940"/><path d="'
        'M3 3h2v1H3zm3 1h1v1H6zM4 6h2v1H4zm4 0h1v1H8zM2 7h2v1H2zm5 0h1v1H7z" fi'
        'll="#79993a"/><path d="M5 4h1v1H5zm1 3h1v1H6z" fill="#7e9e3c"/><path d'
        '="M2 3h1v1H2zm6 0h1v1H8zM1 4h1v1H1zm6 0h1v1H7zm2 1h1v1H9z" fill="#7391'
        '37"/><path d="M0 7h1v1H0zm10 0h1v1h-1zM1 8h1v1H1zm8 0h1v1H9zM2 9h2v1H2'
        'zm5 0h2v1H7z" fill="#678231"/><path d="M5 8h1v1H5zM4 9h1v1H4zm2 0h1v1H'
        '6z" fill="#4e6325"/></g><g id="B"><use href="#z" fill="#1d8dff"/><path'
        ' d="M4 1h1v1H4zm4 1h1v1H8zM1 3h1v1H1zm2 0h1v1H3zm3 0h1v1H6zm3 0h1v1H9z'
        'M4 4h1v1H4zM2 5h1v1H2zm4 0h1v2H6zm2 0h1v1H8z" fill="#1d8dc1"/><path d='
        '"M5 1h1v1H5zm2 1h1v1H7zM5 4h1v1H5zm2 1h1v1H7z" fill="#1b8365"/><path d'
        '="M6 2h1v1H6zM3 4h1v1H3zm4 0h2v1H7zM5 6h1v1H5z" fill="#49a4ff"/><path '
        'd="M3 2h1v1H3z" fill="#1b88ab"/><path d="M5 2h1v1H5zM2 4h1v1H2z" fill='
        '"#2b9189"/><path d="M2 3h1v1H2zm7 1h1v1H9z" fill="#1c8871"/><path d="M'
        '7 3h1v1H7zM5 7h1v1H5z" fill="#1d8d7c"/><path d="M1 5h1v1H1z" fill="#1b'
        '8499"/><path d="M5 5h1v1H5z" fill="#389259"/><path d="M3 6h1v1H3z" fil'
        'l="#1b847c"/><path d="M4 6h1v1H4z" fill="#399dc1"/><path d="M7 6h1v1H7'
        'z" fill="#1c8889"/><use href="#y" fill="#06c"/></g><g id="J"><use href'
        '="#z" fill="#9ea686"/><path d="M5 1h1v1H5zm0 1h2v1H5zM1 3h2v1H1zm7 0h2'
        "v1H8zM4 4h1v1H4zm2 0h2v1H6zM3 5h1v1H3zm6 0h1v1H9zM5 6h1v1H5zm2 0h1v1H7"
        'z" fill="#7f9870"/><path d="M6 1h1v1H6zM3 2h1v1H3zm4 0h1v1H7zM4 3h1v1H'
        '4zM2 4h2v1H2zm3 0h1v1H5zm3 0h1v1H8zM7 5h1v1H7zM2 6h1v1H2zm4 0h1v1H6z" '
        'fill="#9daf92"/><path d="M2 2h1v1H2zm2 0h1v1H4zm4 0h1v1H8zM3 3h1v1H3zm'
        '3 0h1v1H6zM1 5h2v1H1zm4 0h1v1H5zm3 0h1v1H8zM4 7h1v1H4zm2 0h1v1H6z" fil'
        'l="#868f69"/><use href="#y" fill="#657b59"/></g><g id="E"><use href="#'
        'z" fill="#41b344"/><path d="M5 2h1v1H5zM3 3h2v2H3zm3 2h1v1H6z" fill="#'
        '2d9a33"/><path d="M3 2h1v1H3zM2 3h1v1H2zm2 0h1v1H4zm3 0h1v1H7zM6 4h1v1'
        'H6zm2 0h1v1H8zM4 5h1v1H4zM3 6h1v1H3zm2 0h1v1H5z" fill="#2e843c"/><path'
        ' d="M6 1h1v2H6zm2 1h1v1H8zM5 4h1v1H5zm2 1h1v1H7z" fill="#36a642"/><pat'
        'h d="M2 2h1v1H2zm4 1h1v1H6zM1 5h1v1H1zm4 0h1v1H5zm4 0h1v1H9zM5 7h1v1H5'
        'z" fill="#3aac3c"/><path d="M1 3h1v1H1zm1 2h2v1H2z" fill="#309e39"/><p'
        'ath d="M5 3h1v1H5zM1 4h1v1H1z" fill="#43ae4d"/><path d="M8 5h1v1H8z" f'
        'ill="#38bd40"/><path d="M9 4h1v1H9z" fill="#54bf5b"/><use href="#y" fi'
        'll="#277239"/></g><g id="K"><use href="#z" fill="#fff"/><path d="M4 2h'
        '2v1H4zM1 3h1v1H1zm6 1h2v1H7zM3 5h2v1H3zm3 2h1v1H6z" fill="#f3f3f3"/><u'
        'se href="#y" fill="#e4e4e4"/></g><g id="A"><use href="#z" fill="#1f8a2'
        '3"/><use href="#y" fill="#5f4a25"/><path d="M4 1h1v1H4zm2 0h1v1H6zM0 3'
        'h1v2H0zm10 0h1v2h-1z" fill="#6a5329"/><path d="M5 1h1v1H5zM1 3h1v1H1zm'
        '8 0h1v1H9z" fill="#7f6432"/><path d="M2 2h1v1H2zm4 0h3v1H6zM1 4h1v1H1z'
        '" fill="#115c13"/><path d="M3 2h1v1H3zm4 0h1v1H7z" fill="#5f4a25"/><pa'
        'th d="M4 2h1v1H4zM2 3h1v1H2zm6 0h1v1H8zm1 1h1v1H9z" fill="#15771b"/><p'
        'ath d="M6 6h1v1H6zM1 7h7v3H1z" fill="#28af49"/><path d="M3 4h1v1H3zm3 '
        "0h1v2H6zM2 5h3v1H2zm6 0h2v4H8zM1 6h5v1H1zm0 2h1v1H1zm4 0h1v1H5zM3 9h1v"
        '1H3z" fill="#239e42"/><path d="M5 3h3v1H5zm2 1h1v1H7zm2 1h1v1H9z" fill'
        '="#167d1b"/><path d="M3 6h1v1H3zm1 1h1v1H4zm5 0h1v1H9z" fill="#1ca021"'
        '/><path d="M3 5h1v1H3zm4 1h1v1H7zM2 7h1v2H2zm4 0h1v1H6zm2 0h1v1H8z" fi'
        'll="#29bc4f"/><path d="M0 7h1v2H0zm10 0h1v1h-1zM9 8h1v1H9zM1 9h1v1H1zm'
        '3 0h1v1H4zm4 0h1v1H8zm-6 1h2v1H2zm3 0h3v1H5z" fill="#16771b"/><path d='
        '"M0 5h1v2H0zm10 0h1v2h-1z" fill="#1f8a23"/></g><g id="C"><use href="#z'
        '" fill="#5a9e30"/><path d="M5 1h1v1H5zM4 2h1v1H4zm2 0h1v1H6zM1 3h2v1H1'
        'zm7 0h2v1H8z" fill="#7f6432"/><path d="M3 2h1v1H3zm4 0h1v1H7z" fill="#'
        '604a25"/><use href="#y" fill="#604a25"/><path d="M4 1h1v1H4zm2 0h1v1H6'
        'zM2 2h1v1H2zm6 0h1v1H8zM0 3h1v2H0zm10 0h1v2h-1z" fill="#6a5329"/><path'
        ' d="M5 2h1v1H5zM3 3h1v1H3zm4 0h1v1H7zM1 4h1v1H1zm7 0h2v1H8zM0 5h1v2H0z'
        'm10 0h1v1h-1z" fill="#4f8929"/><path d="M2 4h1v1H2zm7 1h1v1H9zM1 6h9v3'
        'H1z" fill="#60a934"/><path d="M5 5h1v1H5zM3 6h1v1H3zm4 0h1v1H7z" fill='
        '"#4f8929"/><path d="M3 7h1v1H3zm4 0h2v2H7zM1 8h2v1H1zm3 0h1v1H4zm1 1h2'
        'v1H5z" fill="#6dbe3a"/><path d="M1 6h2v1H1zm3 0h1v1H4zm5 0h1v1H9zM5 7h'
        '1v1H5zm3 0h1v1H8z" fill="#5a9e30"/><path d="M10 6h1v2h-1zM0 7h1v2H0zm3'
        ' 1h1v1H3zm6 0h1v1H9zM1 9h2v1H1zm3 0h1v1H4zm3 0h2v1H7zm-2 1h2v1H5z" fil'
        'l="#497f27"/></g><g id="D"><use href="#z" fill="#307e36"/><use href="#'
        'y" fill="#215826"/><path d="M1 6h9v3H1zm4 3h1v1H5z" fill="#215826"/><p'
        'ath d="M4 1h3v1H4zM2 2h1v1H2zm6 0h1v1H8zM0 3h1v4H0zm3 0h1v2H3zm3 0h1v3'
        "H6zm4 0h1v4h-1zM9 4h1v1H9zM4 5h1v1H4zm4 0h1v1H8zM3 6h3v1H3zm4 0h1v1H7z"
        "M1 7h2v1H1zm6 0h1v1H7zm2 0h1v1H9zM1 8h1v1H1zm2 0h7v1H3zM2 9h1v1H2zm2 0"
        'h1v1H4zm2 0h1v1H6zm3 0h1v1H9zm-4 1h1v1H5z" fill="#296d2f"/><path d="M4'
        " 2h2v1H4zm0 1h1v1H4zm4 0h1v1H8zM2 4h1v1H2zm7 1h1v1H9zM4 6h1v2H4zm2 1h1"
        'v1H6zM5 8h1v1H5zm3 0h1v1H8z" fill="#338839"/></g></g><g transform="rot'
        'ate(180 62.5 54.5)">';

    /// @notice Ending string for the island's SVG
    string constant ISLAND_SVG_END = "</g></svg>";

    // -------------------------------------------------------------------------
    // `render` and `_renderIsland`
    // -------------------------------------------------------------------------

    /// @notice Renders a Curta Golf King NFT SVG.
    /// @param _id The token ID of the Curta Golf King NFT.
    function render(uint256 _id) internal pure returns (string memory) {
        uint32 seed = uint32(uint256(keccak256(abi.encodePacked(_id))));

        return _renderIsland(seed);
    }

    /// @notice A helper function to render the island's SVG for a given seed.
    /// @param _seed The seed used to generate the island.
    /// @return The island's SVG.
    function _renderIsland(uint32 _seed) internal pure returns (string memory) {
        string memory svg = ISLAND_SVG_START;

        unchecked {
            uint256[HEIGHT][WIDTH] memory perlin1;
            uint256[HEIGHT][WIDTH] memory perlin2;
            uint32 seed1 = _seed;
            uint32 seed2 = _seed + 1;
            (uint256 min1, uint256 max1) = (MAX, 0);
            (uint256 min2, uint256 max2) = (MAX, 0);

            // Loop through each tile coordinate and generate the Perlin noise
            // value at that coordinate for each of the two seeds.
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
                    // 2d-array of generated Perlin noise values to normalize
                    // them later.
                    if (noise1 < min1) min1 = noise1;
                    if (noise1 > max1) max1 = noise1;
                    if (noise2 < min2) min2 = noise2;
                    if (noise2 > max2) max2 = noise2;
                }
            }

            // Compute the range of values within each 2d-array for
            // normalization.
            uint256 range1 = max1 - min1;
            range1 = range1 == 0 ? 1 : range1; // Avoid division by zero.
            uint256 range2 = max2 - min2;
            range2 = range2 == 0 ? 1 : range2; // Avoid division by zero.

            // Select the tiles depending on `perlin1` and `perlin2` and
            // generate the SVG string.
            for (uint256 row; row < HEIGHT; ++row) {
                for (uint256 col; col < WIDTH; ++col) {
                    // Exclude the tile if it is not part of the island's shape.
                    // We determine whether a tile at a given `(row, col)` is
                    // part of the island via a bitmap, where a `1` at the LSb
                    // position equal to `12 * row + col` indicates the tile is
                    // part of the island. i.e. the bitmap below are the
                    // following bits concatenated together:
                    // ```
                    // 000111111000
                    // 001111111000
                    // 001111111100
                    // 011111111100
                    // 011111111110
                    // 111111111110
                    // 111111111111
                    // 111111111110
                    // 111111111111
                    // 111111111110
                    // 111111111111
                    // 111111111110
                    // 011111111110
                    // 011111111100
                    // 001111111100
                    // 001111111000
                    // 000111111000
                    // ```
                    if (
                        (0x1f83f83fc7fc7feffefffffefffffefffffe7fe7fc3fc3f81f8 >> (12 * row + col))
                            & 1 == 0
                    ) continue;

                    // Normalize the Perlin noise values to the range [0, 59].
                    uint256 temperature = 60 * (perlin1[col][row] - min1) / range1;
                    uint256 rainfall = 60 * (perlin2[col][row] - min2) / range2;

                    // Select the tile based on the temperature and rainfall:
                    //      | Rainfall | Temperature | Tile type        |
                    //      | -------- | ----------- | ---------------- |
                    //      | [ 0, 11] | [ 0, 59]    | Rainforest       |
                    //      | [12, 23] | [ 0, 29]    | Rainforest       |
                    //      |          | [30, 59]    | Wetland          |
                    //      | [24, 35] | [ 0, 19]    | Temperate forest |
                    //      |          | [20, 39]    | Boreal forest    |
                    //      |          | [40, 59]    | Marsh            |
                    //      | [36, 47] | [ 0, 29]    | Plains           |
                    //      |          | [30, 59]    | Grassland        |
                    //      | [47, 59] | [ 0, 14]    | Desert           |
                    //      |          | [15, 29]    | Plains           |
                    //      |          | [30, 44]    | Tundra           |
                    //      |          | [45, 59]    | Snow             |
                    string memory tileType = "";
                    assembly {
                        // Store length of 1 for `tileType`.
                        mstore(tileType, 1)
                        // Compute the tile type based on the temperature and
                        // rainfall, then store it in `tileType`.
                        mstore(
                            // Compute offset for `tileType`'s content.
                            add(tileType, 0x20),
                            // Right-pad the tile type with `31`s.
                            shl(
                                0xf8,
                                // Equivalent to the following:
                                // ```sol
                                // tileType = 0x41 + (
                                //     TILE_VALUES >> (48 * (rainfall / 12) + 4 * (temperature / 5))
                                // ) & 0xf;
                                // ```
                                add(
                                    and(
                                        shr(
                                            add(
                                                mul(div(rainfall, 12), 48),
                                                shl(2, div(temperature, 5))
                                            ),
                                            // A bitmap of 4-bit words
                                            // corresponding to tile type
                                            // value offsets required for the
                                            // table above.
                                            0xaaa999888555777666666555555444433332222111111000000000000000000
                                        ),
                                        // Mask 4 bits for the word.
                                        0xf
                                    ),
                                    // ASCII value for `A`; this way, the tile
                                    // type will be an ASCII character in the
                                    // range `0x41` and `0x4b` (`A` through
                                    // `K`).
                                    0x41
                                )
                            )
                        )
                    }

                    // Compute `x` and `y` coordinates for the tile.
                    uint256 x;
                    uint256 y;
                    assembly {
                        // Equivalent to `x = 112 - col * 10 + 5 * (row & 1)`.
                        // 112 is the width of the island SVG (125) minus 2px
                        // for left padding, and 11px for the width of the tile.
                        // We subtract the width because we rotate the group of
                        // tiles by 180°, so the `x`-coordinate effectively
                        // corresponds to the right side of the tile in this
                        // context. Then, from 112, we subtract the 10px for
                        // each column width because we want each tile to have
                        // 1px of overlap with the previous tile. Finally, we
                        // add 5px for each odd row to get the hexagonal offset.
                        x := add(sub(112, mul(col, 10)), mul(5, and(row, 1)))
                        // Equivalent to `y = 98 - row * 6`. Similar to the 112
                        // for the `x`-coordinate, 98 is the height of the
                        // island SVG (109) minus 2px for top padding, and 9px
                        // for the height of the tile. Also similarly, we
                        // subtract 6px for each row height (as opposed to the
                        // full 9px) because we want the hexagonal tiling.
                        y := sub(98, mul(row, 6))
                    }
                    svg = string.concat(
                        svg,
                        '<use href="#',
                        tileType,
                        '" x="',
                        x.toString(),
                        '" y="',
                        y.toString(),
                        '"/>'
                    );
                }
            }
        }

        // Return SVG string.
        return string.concat(svg, ISLAND_SVG_END);
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
