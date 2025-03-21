// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { DeployScriptBase } from "./utils/DeployScriptBase.sol";
import { GenericSwapFacet } from "rubic/Facets/GenericSwapFacet.sol";

contract DeployScript is DeployScriptBase {
    constructor() DeployScriptBase("GenericSwapFacet") {}

    function run() public returns (GenericSwapFacet deployed) {
        vm.startBroadcast(deployerPrivateKey);

        if (isDeployed()) {
            return GenericSwapFacet(predicted);
        }

        deployed = GenericSwapFacet(
            factory.deploy(salt, type(GenericSwapFacet).creationCode)
        );

        vm.stopBroadcast();
    }
}
