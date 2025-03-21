// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "sphinx-forge-std/Script.sol";
import {Sphinx} from "../contracts/foundry/Sphinx.sol";
import {Network, Label} from "@sphinx-labs/contracts/contracts/foundry/SphinxPluginTypes.sol";
import {MyContract1} from "../contracts/test/MyContracts.sol";
import {CREATE3} from "solady/utils/CREATE3.sol";

contract Sample is Sphinx {
    MyContract1 myContract;

    function setUp() public {
        sphinxConfig.projectName = "11/10";
        sphinxConfig.owners = [0x9fd58Bf0F2E6125Ffb0CBFa9AE91893Dbc1D5c51, 0xFBD0C9AA5356577F09e8cA7681A88cC8C9DF52F0, 0xaecFD89752218c7C4ab6A679CdE5494F88272779];
        sphinxConfig.threshold = 2;
        sphinxConfig.testnets = [Network.goerli, Network.arbitrum_goerli];
        sphinxConfig.orgId = "clo6byksj0001cbld6lelntej";
    }

    function run() public override sphinx {
        new MyContract1{ salt: bytes32(uint(1)) }(
            -1,
            2,
            address(1),
            address(2)
        );
        new MyContract1{ salt: bytes32(uint(2)) }(
            -1,
            2,
            address(1),
            address(2)
        );
        new MyContract1{ salt: bytes32(uint(3)) }(
            -1,
            2,
            address(1),
            address(2)
        );

        bytes memory initCode =
            abi.encodePacked(type(MyContract1).creationCode, abi.encode(1, 2, address(1), address(2)));
        address deployed = CREATE3.deploy(bytes32(0), initCode, 0);
        sphinxLabel(deployed, "contracts/test/MyContracts.sol:MyContract1");
    }
}
