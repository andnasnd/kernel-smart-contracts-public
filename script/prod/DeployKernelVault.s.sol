// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { KernelConfig } from "src/KernelConfig.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

contract DeployKernelVault is BaseScript {
    /**
     * @param configAddr address of the deployed KernelConfiguration (the UUPS proxy)
     * @param vaultUpgradeableBeacon address of the KernelVault Beacon (deployed with Beacon proxy)
     * @param assetAddr addess of ERC20 token managed by the deployed Vault
     */
    function run(address configAddr, address vaultUpgradeableBeacon, address assetAddr) external {
        _deploy(configAddr, vaultUpgradeableBeacon, assetAddr);
    }

    /// @notice Deploy
    function _deploy(address configAddr, address vaultUpgradeableBeacon, address assetAddr) internal {
        // start broadcast
        _startBroadcast();

        //
        DeployOutput memory deployOutput;
        deployOutput.config = KernelConfig(configAddr);
        deployOutput.assetRegistry = IAssetRegistry(deployOutput.config.getAssetRegistry());
        deployOutput.vaultUpgradeableBeacon = UpgradeableBeacon(vaultUpgradeableBeacon);

        // print users debug
        _printUsersDebug();

        // deploy KernelVault
        console.log("##### KernalVault");
        _deployKernelVault(deployOutput, IERC20(assetAddr));

        _stopBroadcast();
    }
}
