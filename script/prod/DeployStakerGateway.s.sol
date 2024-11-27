// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { KernelConfig } from "src/KernelConfig.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

contract DeployStakerGateway is BaseScript {
    /**
     * @param configAddr address of the deployed KernelConfiguration (the UUPS proxy)
     */
    function run(address configAddr) external {
        _deploy(configAddr);
    }

    /// @notice Deploy
    function _deploy(address configAddr) internal {
        // start broadcast
        _startBroadcast();

        //
        DeployOutput memory deployOutput;
        deployOutput.config = KernelConfig(configAddr);

        // print users debug
        _printUsersDebug();

        // deploy StakerGateway
        _deployStakerGateway(deployOutput);

        _stopBroadcast();
    }
}
