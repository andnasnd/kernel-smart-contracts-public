// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

contract DeployKernelVaultBeacon is BaseScript {
    /**
     *
     */
    function run() external {
        _deploy();
    }

    /// @notice Deploy
    function _deploy() internal {
        // start broadcast
        _startBroadcast();

        //
        DeployOutput memory deployOutput;

        // print users debug
        _printUsersDebug();

        // deploy KernelVault Beacon
        console.log("##### KernalVault Beacon");
        _deployKernelVaultUpgradeableBeacon(deployOutput);

        _stopBroadcast();
    }
}
