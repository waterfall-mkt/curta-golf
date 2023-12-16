// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { LibString } from "solady/utils/LibString.sol";

import { Perlin } from "src/utils/Perlin.sol";

/// @title Curta Golf King NFT art
/// @notice A library for generating SVGs for {CurtaGolf}.
/// @dev Must be compiled with `--via-ir` to avoid stack too deep errors.
/// @author fiveoutofnine
library KingArt {
    using LibString for string;
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

    /// @notice Starting string for the SVG.
    string constant SVG_START =
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" vie'
        'wBox="0 0 1024 1024" fill="none"><style>@font-face{font-family:A;src:u'
        "rl(data:font/woff2;utf-8;base64,d09GMgABAAAAAA4gABAAAAAAHHQAAA3CAAEAAA"
        "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"
        "jR+JD+r3al8q/xP+dNlAAAAA==)}@font-face{font-family:B;src:url(data:font"
        "/woff2;utf-8;base64,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)}div.a{disp"
        "lay:flex}div.b{font-family:A;font-size:40px;line-height:48px;color:#c1"
        "cdd9;letter-spacing:-.05em}div.c{font-family:B;line-height:1;font-size"
        ":24px;color:#758195}div.d{gap:16px}div.e{flex-direction:column;align-i"
        "tems:start}text,tspan{dominant-baseline:central;font-size:40px;line-he"
        "ight:48px}.a{font-family:A;letter-spacing:-.05em;fill:#F0F6FC;}.b{font"
        '-family:B;fill:#94A3B3}</style><path d="M0 0h1024v1024H0z" fill="#1216'
        '1F"/><g fill="#0D1017"><path d="M0 0h1024v40H0zm0 984h1024v40H0z"/><pa'
        'th d="M0 0h40v1024H0zm984 0h40v1024h-40z"/></g><g stroke="#27303D" str'
        'oke-width="2"><path d="M0 40h1024M0 984h1024M40 0v1024M984 0v1024"/><p'
        'ath d="M88 208v600q0 24 24 24h800q24 0 24-24V208q0-24-24-24H112q-24 0-'
        '24 24z" fill="#181E28"/><path d="M88 96v48q0 8 8 8h48q8 0 8-8V96q0-8-8'
        '-8H96q-8 0-8 8z" fill="#000"/></g><g fill="#94A3B3" transform="transla'
        'te(104 102)"><rect width="8" height="26" rx="4"/><circle cx="4" cy="32'
        '" r="4"/><rect x="12" width="8" height="12" rx="4"/><circle cx="16" cy'
        '="18" r="4"/><rect x="12" y="24" width="8" height="12" rx="4"/><circle'
        ' cx="28" cy="4" r="4"/><rect x="24" y="10" width="8" height="26" rx="4'
        '"/></g><text x="172" y="120"><tspan class="a">Curta</tspan><tspan clas'
        's="b"> | Golf</tspan></text><g transform="matrix(5.12 0 0 5.12 192 228'
        '.96)">';

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

    // -------------------------------------------------------------------------
    // `render` and `_renderIsland`
    // -------------------------------------------------------------------------

    /// @notice Renders a Curta Golf King NFT SVG.
    /// @param _id The token ID of the Curta Golf King NFT.
    /// @param _metadata The last 96 bits (LSb) of the corresponding course's
    /// King's address.
    /// @param _solves The number of solves for the corresponding course.
    /// @param _gasUsed The amount of gas used by the leading solution on the
    /// course.
    function render(uint256 _id, uint96 _metadata, uint32 _solves, uint32 _gasUsed)
        public
        pure
        returns (string memory)
    {
        uint32 seed = uint32(uint256(keccak256(abi.encodePacked(_id))));

        return string.concat(
            SVG_START,
            _renderIsland(seed),
            '</g><foreignObject x="88" y="864" width="848" height="72" stroke="'
            '#758195" stroke-width="2" stroke-linecap="round" stroke-linejoin="'
            'round"><div class="a" style="gap:40px" xmlns="http://www.w3.org/19'
            '99/xhtml"><div class="a d"><svg xmlns="http://www.w3.org/2000/svg"'
            ' width="40" height="48" viewBox="0 0 24 24" fill="none"><path d="M'
            '18 20a6 6 0 0 0-12 0"/><circle cx="12" cy="10" r="4"/><circle cx="'
            '12" cy="12" r="10"/></svg><div class="a e"><div class="b">',
            _formatValueAsAddress(_metadata >> 68),
            '</div><div class="c">King</div></div></div><div class="a d"><svg x'
            'mlns="http://www.w3.org/2000/svg" width="40" height="48" viewBox="'
            '0 0 24 24" fill="none"><path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4'
            ' 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 '
            '4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z"/><pat'
            'h d="m9 12 2 2 4-4"/></svg><div class="a e"><div class="b">',
            _formatNumber(_solves),
            '</div><div class="c">Solves</div></div></div><div class="a d"><svg'
            ' xmlns="http://www.w3.org/2000/svg" width="40" height="48" viewBox'
            '="0 0 24 24" fill="none"><path d="M3 22h12M4 9h10m0 13V4a2 2 0 0 0'
            '-2-2H6a2 2 0 0 0-2 2v18m10-9h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2h0a2 2'
            ' 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.42L18 5"/></svg><div class="a e"><'
            'div class="b">',
            _formatNumber(_gasUsed),
            '</div><div class="c">Gas used</div></div></div></div></foreignObje'
            'ct></svg>'
        );
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
        return string.concat(svg, "</g></svg>");
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

    /// @notice A helper function to format a 28 bit value as a hex-string of
    /// length 7. If the value is less than 24 bits, it is padded with leading
    /// zeros.
    /// @param _value The value to format.
    /// @return The formatted string.
    function _formatValueAsAddress(uint256 _value) internal pure returns (string memory) {
        return string.concat(
            string(abi.encodePacked(bytes32("0123456789ABCDEF")[(_value >> 24) & 0xF])),
            (_value & 0xFFFFFF).toHexStringNoPrefix(3).toCase(true)
        );
    }

    /// @notice A helper function to format a number with a `K` or `M` suffix if
    /// it is greater than 1,000 or 1,000,000, respectively.
    /// @param _value The value to format.
    /// @return The formatted string.
    function _formatNumber(uint256 _value) internal pure returns (string memory) {
        if (_value < 1000) return _value.toString();
        if (_value < 1_000_000) {
            return string.concat(
                (_value / 1000).toString(), ".", ((_value % 1000) / 100).toString(), "K"
            );
        }
        return string.concat(
            (_value / 1_000_000).toString(), ".", ((_value % 1_000_000) / 100_000).toString(), "M"
        );
    }
}
