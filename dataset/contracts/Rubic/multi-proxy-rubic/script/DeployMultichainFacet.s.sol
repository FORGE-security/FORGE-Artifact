// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { DeployScriptBase } from "./utils/DeployScriptBase.sol";
import { MultichainFacet } from "rubic/Facets/MultichainFacet.sol";

contract DeployScript is DeployScriptBase {
    constructor() DeployScriptBase("MultichainFacet") {}

    function run() public returns (MultichainFacet deployed) {
        vm.startBroadcast(deployerPrivateKey);

        if (isDeployed()) {
            return MultichainFacet(predicted);
        }

        deployed = MultichainFacet(
            factory.deploy(salt, type(MultichainFacet).creationCode)
        );

        vm.stopBroadcast();
    }
}
