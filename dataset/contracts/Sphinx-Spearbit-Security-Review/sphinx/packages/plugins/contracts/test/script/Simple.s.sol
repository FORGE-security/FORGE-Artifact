// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Script } from "sphinx-forge-std/Script.sol";
import { MyContract2 } from "../../../contracts/test/MyContracts.sol";
import { Sphinx } from "../../foundry/Sphinx.sol";
import { Network } from "@sphinx-labs/contracts/contracts/foundry/SphinxPluginTypes.sol";

contract Simple is Script, Sphinx {
    constructor() {
        sphinxConfig.projectName = "Simple Project";
        sphinxConfig.owners = [0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266];
        sphinxConfig.threshold = 1;

        sphinxConfig.mainnets = [Network.ethereum, Network.optimism];
        sphinxConfig.testnets = [Network.goerli];
        sphinxConfig.orgId = "test-org-id";
    }

    function run() public override sphinx {
        MyContract2 myContract;
        Network network = getSphinxNetwork(block.chainid);
        if (network == Network.ethereum || network == Network.goerli) {
            myContract = new MyContract2{ salt: 0 }();
        } else if (network == Network.optimism) {
            myContract = new MyContract2{ salt: bytes32(uint(1)) }();
        }
        myContract.incrementMyContract2(2);
    }
}
