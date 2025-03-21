// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { DeployScriptBase } from "./utils/DeployScriptBase.sol";
import { stdJson } from "forge-std/Script.sol";
import { StargateFacet } from "rubic/Facets/StargateFacet.sol";

contract DeployScript is DeployScriptBase {
    using stdJson for string;

    constructor() DeployScriptBase("StargateFacet") {}

    function run()
        public
        returns (StargateFacet deployed, bytes memory constructorArgs)
    {
        string memory path = string.concat(
            vm.projectRoot(),
            "/config/stargate.json"
        );
        string memory json = vm.readFile(path);
        address stargateRouter = json.readAddress(
            string.concat(".routers.", network)
        );

        constructorArgs = abi.encode(stargateRouter);

        vm.startBroadcast(deployerPrivateKey);

        if (isDeployed()) {
            return (StargateFacet(payable(predicted)), constructorArgs);
        }

        deployed = StargateFacet(
            payable(
                factory.deploy(
                    salt,
                    bytes.concat(
                        type(StargateFacet).creationCode,
                        constructorArgs
                    )
                )
            )
        );

        vm.stopBroadcast();
    }
}
