// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Script, console } from "forge-std/Script.sol";

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

    /// @notice The expected address of the deployed `CurtaGolf` contract.
    address curtaGolfAddress = 0x8936272ebecc127D21BdC0DbD35978DC7bB7F358;

    /// @notice Address of the create2 factory to use
    address create2Factory = 0x0000000000FFe8B47B3e2130213B802212439497;

    function run() public {
        vm.startBroadcast();

        // Deploy `PurityChecker`.
        purityChecker = new PurityChecker();

        // Deploy `Par`.
        par = new Par(curtaGolfAddress);

        // Deploy `CurtaGolf`.
        curtaGolf = new CurtaGolf(par, purityChecker);

        // create2Factory.call(abi.encodeWithSignature(
        //     "safeCreate2(bytes32,bytes)",
        //     0x5f3146d3d700245e998660dbcae97dcd7a554c05c8292664421e00010df48664,
        //     abi.encodePacked(
        //         type(CurtaGolf).creationCode,
        //         abi.encode(address(par), address(purityChecker))
        //     )
        // ));

        curtaGolf.transferOwnership(0xB6a7803FF52199A4bBBf902d6fb61069d1b1676a);

        vm.stopBroadcast();
    }
}
