// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";

import { CurtaGolf } from "src/CurtaGolf.sol";
import { Par } from "src/Par.sol";
import { PurityChecker } from "src/utils/PurityChecker.sol";

contract Deploy is Script {

    // -------------------------------------------------------------------------
    // Deployment addresses
    // -------------------------------------------------------------------------

    /// @notice The instance of `CurtaGolf` that will be deployed.
    CurtaGolf public curtaGolf;

    /// @notice The instance of `Par` that will be deployed.
    Par public par;

    /// @notice The instance of `PurityChecker` that will be deployed.
    PurityChecker public purityChecker;

    /// @notice The deployer address for `curta-golf`.
    address public deployer = 0x5F3146D3D700245E998660dBCAe97DcD7a554c05;

    function run() public {
        vm.startBroadcast();

        purityChecker = new PurityChecker();

        // We get what the nonce will be after first deploying `Par.sol`.
        address curtaGolfAddress = LibRLP.computeAddress(deployer, vm.getNonce(deployer) + 1);

        par = new Par(curtaGolfAddress);

        curtaGolf = new CurtaGolf(par, purityChecker);

        curtaGolf.transferOwnership(0xA85572Cd96f1643458f17340b6f0D6549Af482F5);

        vm.stopBroadcast();
    }
}
