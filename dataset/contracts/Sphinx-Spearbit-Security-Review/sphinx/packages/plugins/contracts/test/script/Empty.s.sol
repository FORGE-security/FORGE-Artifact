// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Script } from "sphinx-forge-std/Script.sol";
import { Network } from "@sphinx-labs/contracts/contracts/foundry/SphinxPluginTypes.sol";
import { MyContract1 } from "../../../contracts/test/MyContracts.sol";
import { Sphinx } from "../../foundry/Sphinx.sol";

contract Empty is Script, Sphinx {
    constructor() {
        sphinxConfig.projectName = "Simple Project";
        sphinxConfig.owners = [0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266];
        sphinxConfig.threshold = 1;

        sphinxConfig.mainnets = [Network.ethereum, Network.optimism];
        sphinxConfig.testnets = [Network.goerli, Network.optimism_goerli];
        sphinxConfig.orgId = "test-org-id";
    }

    function run() public override sphinx {}
}
