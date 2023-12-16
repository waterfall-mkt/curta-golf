// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { LibString } from "solady/utils/LibString.sol";

/// @title Curta Golf Par NFT art
/// @notice A library for generating SVGs for {Par}.
/// @author fiveoutofnine
library ParArt {
    using LibString for string;
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice Starting string for the SVG.
    string constant SVG_START =
        '<svg width="750" height="750" xmlns="http://www.w3.org/2000/svg" fill='
        '"none" viewBox="0 0 750 750"><style>@font-face{font-family:A;src:url(d'
        'ata:font/ttf;utf-8;base64,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'
        '1irgEAAA==)}.a{filter:url(#c)drop-shadow(0 0 2px #007fff);fill:#fff;wi'
        'dth:4px}.b{filter:drop-shadow(0 0 .5px #007fff);fill:#000;width:3px}.c'
        '{height:13px}.d{height:6px}.e{height:4px}.f{height:12px}.g{height:5px}'
        '.h{height:3px}.i{width:620px;height:320px}.j{cy:375px;r:20px}.k{stroke'
        ':#27303d}.l{fill:#000}.n{fill:#0d1017}.o{stroke-width:2px}div.z{displa'
        'y:flex;color:#c1cdd9;align-items:center}div.y{font-family:A;gap:6px;fo'
        'nt-size:20px;line-height:24px;letter-spacing:-.05em}div.x{padding:2px}'
        '</style><defs><filter id="c"><feGaussianBlur stdDeviation="8" in="Sour'
        'ceGraphic" result="offset-blur"/><feComposite operator="out" in="Sourc'
        'eGraphic" in2="offset-blur" result="inverse"/><feFlood flood-color="#0'
        '07FFF" flood-opacity=".95" result="color"/><feComposite operator="in" '
        'in="color" in2="inverse" result="shadow"/><feComposite in="shadow" in2'
        '="SourceGraphic"/><feComposite operator="atop" in="shadow" in2="Source'
        'Graphic"/></filter><mask id="a"><path fill="#000" d="M0 0h750v750H0z"/'
        '><rect class="i" x="65" y="215" rx="20" fill="#FFF"/><circle class="j '
        'l" cx="65"/><circle class="j l" cx="685"/></mask></defs><path fill="#1'
        '0131C" d="M0 0h750v750H0z"/><rect class="i n" x="65" y="215" mask="url'
        '(#a)" rx="20"/><circle class="k n" cx="375" cy="312.5" r="24"/><g tran'
        'sform="translate(359 296.5)"><circle class="n" cy="16" cx="16" r="16"/'
        '><rect class="a c" x="8" y="7" rx="2"/><rect class="b f" x="8.5" y="7.'
        '5" rx="1.5"/><rect class="a e" x="8" y="21" rx="2"/><rect class="b h" '
        'x="8.5" y="21.5" rx="1.5"/><rect class="a d" x="14" y="7" rx="2"/><rec'
        't class="b g" x="14.5" y="7.5" rx="1.5"/><rect class="a e" x="14" y="1'
        '4" rx="2"/><rect class="b h" x="14.5" y="14.5" rx="1.5"/><rect class="'
        'a d" x="14" y="19" rx="2"/><rect class="b g" x="14.5" y="19.5" rx="1.5'
        '"/><rect class="a c" x="20" y="12" rx="2"/><rect class="b f" x="20.5" '
        'y="12.5" rx="1.5"/><rect class="a e" x="20" y="7" rx="2"/><rect class='
        '"b h" x="20.5" y="7.5" rx="1.5"/></g><path fill="#F0F6FC" d="M319.971 '
        '361.785a4.15 4.15 0 0 1-1.555-.288 4.243 4.243 0 0 1-1.317-.91 4.243 4'
        '.243 0 0 1-.91-1.316 4.15 4.15 0 0 1-.287-1.556v-.503c0-.558.096-1.084'
        '.288-1.58.207-.478.51-.917.91-1.316a3.912 3.912 0 0 1 1.315-.885 3.87 '
        '3.87 0 0 1 1.555-.311h6.392c.367 0 .718.048 1.053.143.319.08.638.216.9'
        '57.407.335.176.622.383.862.623.24.239.455.518.646.837.064.096.104.2.12'
        '.311a.45.45 0 0 1-.024.144.52.52 0 0 1-.264.383.63.63 0 0 1-.478.048.5'
        '.5 0 0 1-.36-.287 4.528 4.528 0 0 0-.454-.599 3.924 3.924 0 0 0-.622-.'
        '455 2.903 2.903 0 0 0-.694-.287 2.303 2.303 0 0 0-.742-.072c-1.07 0-2.'
        '13-.008-3.184-.023-1.07 0-2.138.007-3.208.023-.398 0-.765.064-1.1.192a'
        '2.659 2.659 0 0 0-.934.646 2.982 2.982 0 0 0-.646.934 2.942 2.942 0 0 '
        '0-.216 1.125v.502a2.766 2.766 0 0 0 .862 2.035 2.766 2.766 0 0 0 2.035'
        '.862h6.391c.255 0 .494-.024.718-.072a3.03 3.03 0 0 0 .67-.287 2.66 2.6'
        '6 0 0 0 .598-.407c.16-.16.311-.343.455-.55a.657.657 0 0 1 .383-.216.62'
        '.62 0 0 1 .407.095c.128.08.207.2.24.36a.459.459 0 0 1-.049.406 3.979 3'
        '.979 0 0 1-.646.79c-.24.208-.519.4-.838.575-.319.175-.63.295-.933.359-'
        '.32.08-.655.12-1.005.12h-6.392Zm26.33 0c-1.069 0-1.986-.4-2.752-1.197-'
        '.766-.798-1.15-1.764-1.15-2.897v-3.997c0-.175.057-.319.168-.43a.554.55'
        '4 0 0 1 .407-.168c.176 0 .32.056.431.167a.584.584 0 0 1 .168.431v3.997'
        'c0 .798.27 1.484.813 2.059a2.561 2.561 0 0 0 1.94.838h5.816a2.56 2.56 '
        '0 0 0 1.938-.838c.543-.575.814-1.26.814-2.059v-3.997a.58.58 0 0 1 .168'
        '-.43.583.583 0 0 1 .43-.168c.16 0 .296.056.408.167a.584.584 0 0 1 .167'
        '.431v3.997c0 1.133-.383 2.099-1.149 2.897-.766.798-1.691 1.197-2.776 1'
        '.197h-5.84Zm35.737-1.078c.112.08.192.176.24.288a.892.892 0 0 1 .023.21'
        '5.707.707 0 0 1-.024.168.531.531 0 0 1-.215.31.633.633 0 0 1-.36.097h-'
        '.07a.213.213 0 0 1-.097-.024c-.032 0-.056-.008-.072-.024a.276.276 0 0 '
        '1-.071-.048c-.575-.4-1.141-.798-1.7-1.197l-1.675-1.197c-.016 0-.024-.0'
        '08-.024-.024-.016 0-.024-.008-.024-.024-.016 0-.024-.008-.024-.024h-8.'
        '33v1.987a.58.58 0 0 1-.167.43.638.638 0 0 1-.431.168.554.554 0 0 1-.40'
        '7-.167.584.584 0 0 1-.168-.43v-7.421c0-.08.008-.16.024-.24a.753.753 0 '
        '0 1 .144-.19.561.561 0 0 1 .191-.12.475.475 0 0 1 .216-.048h10.34c.383'
        ' 0 .734.072 1.053.216.335.128.63.327.886.598.271.272.479.567.622.886.1'
        '28.335.192.686.192 1.053v.503c0 .335-.048.646-.144.933a3.17 3.17 0 0 1'
        '-.479.79 2.3 2.3 0 0 1-.694.623c-.255.16-.542.279-.861.359l1.053.766c.'
        '35.255.702.518 1.053.79Zm-12.423-6.343v3.639h9.742c.224 0 .423-.04.599'
        '-.12.191-.064.359-.176.502-.335.16-.16.28-.327.36-.503a1.6 1.6 0 0 0 .'
        '119-.622v-.479c0-.223-.04-.423-.12-.598a1.843 1.843 0 0 0-.335-.527 1.'
        '842 1.842 0 0 0-.526-.335 1.43 1.43 0 0 0-.599-.12h-9.742Zm37.005-1.17'
        '3c.16 0 .304.056.431.168a.554.554 0 0 1 .168.407c0 .175-.056.32-.168.4'
        '3a.638.638 0 0 1-.43.168h-5.458v6.87c0 .16-.056.295-.168.407a.521.521 '
        '0 0 1-.407.191.595.595 0 0 1-.43-.191.554.554 0 0 1-.168-.407v-6.87h-5'
        '.457a.554.554 0 0 1-.407-.167.584.584 0 0 1-.168-.431c0-.16.056-.295.1'
        '68-.407a.554.554 0 0 1 .407-.168h12.087Zm23.673-.071c1.085 0 2.011.399'
        ' 2.777 1.196.766.798 1.149 1.756 1.149 2.873v4.021c0 .16-.056.295-.168'
        '.407a.594.594 0 0 1-.431.191.52.52 0 0 1-.406-.191.52.52 0 0 1-.192-.4'
        '07v-1.795h-11.298v1.795c0 .16-.064.295-.191.407a.523.523 0 0 1-.407.19'
        '1.52.52 0 0 1-.407-.191.52.52 0 0 1-.192-.407v-4.02c0-1.117.383-2.075 '
        '1.149-2.873.766-.797 1.692-1.196 2.777-1.196h5.84Zm-8.545 5.122h11.322'
        'v-1.053c0-.798-.263-1.476-.79-2.035-.542-.574-1.189-.861-1.939-.861h-5'
        '.84c-.766 0-1.412.287-1.939.861-.543.559-.814 1.237-.814 2.035v1.053Z"'
        '/><text x="375" y="390.5" style="font-family:A;fill:#f0f6fc;dominant-b'
        'aseline:central;text-anchor:middle;font-size:40px;line-height:48px;let'
        'ter-spacing:-.05em">Golf</text><foreignObject x="85" y="491" width="58'
        '0" height="24" stroke="#758195" stroke-width="2" stroke-linecap="round'
        '" stroke-linejoin="round"><div class="z" xmlns="http://www.w3.org/1999'
        '/xhtml"><div class="z" style="margin:0 auto;gap:16px"><div class="z y"'
        '><div class="z x"><svg xmlns="http://www.w3.org/2000/svg" width="20" h'
        'eight="20" viewBox="0 0 24 24" fill="none"><path d="M18 20a6 6 0 0 0-1'
        '2 0"/><circle cx="12" cy="10" r="4"/><circle cx="12" cy="12" r="10"/><'
        '/svg></div><div>';

    // -------------------------------------------------------------------------
    // `render` and `_renderIsland`
    // -------------------------------------------------------------------------

    /// @notice Renders a Par NFT SVG.
    /// @param _id The token ID of the Par NFT.
    function render(uint256 _id, uint32 _gasUsed) public pure returns (string memory) {
        return string.concat(
            SVG_START,
            _formatValueAsAddress((_id >> 132) & 0xfffffff),
            '</div></div><div class="z y"><div class="z x"><svg xmlns="http://w'
            'ww.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fil'
            'l="none"><path d="m12 8 6-3-6-3v10"/><path d="m8 11.99-5.5 3.14a1 '
            "1 0 0 0 0 1.74l8.5 4.86a2 2 0 0 0 2 0l8.5-4.86a1 1 0 0 0 0-1.74L16"
            ' 12m-9.51.85 11.02 6.3m0-6.3L6.5 19.15"/></svg></div><div>',
            (_id >> 160).toString(),
            '</div></div><div class="z y"><div class="z x"><svg xmlns="http://w'
            'ww.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fil'
            'l="none"><path d="M3 22h12M4 9h10m0 13V4a2 2 0 0 0-2-2H6a2 2 0 0 0'
            "-2 2v18m10-9h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2h0a2 2 0 0 0 2-2V9.83a"
            '2 2 0 0 0-.59-1.42L18 5"/></svg></div><div>',
            _formatNumber(_gasUsed),
            '</div></div></div></div></foreignObject><rect class="i k o" x="65"'
            ' y="215" mask="url(#a)" rx="20"/><circle class="j k o" cx="65" mas'
            'k="url(#a)"/><circle class="j k o" cx="685" mask="url(#a)"/></svg>'
        );
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

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
