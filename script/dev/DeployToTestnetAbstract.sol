// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { ERC20Demo } from "test/mock/ERC20Demo.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

import { KernelVault } from "src/KernelVault.sol";

abstract contract DeployToTestnetAbstract is BaseScript {
    /**
     * @notice Deploy the whole protocl in testnet, including mock ERC20 tokens
     * @param wbnbAddress mandatory, address of the WBNB contract to support native staking/unstaking
     * @param erc20Tokens pre-existing ERC20 tokens to add in the asset registry
     */
    function _deploy(address wbnbAddress, address[] memory erc20Tokens) internal {
        require(wbnbAddress != address(0), "WBNB address is mandatory");

        bool deployDemoTokens = vm.parseBool(vm.prompt("Deploy demo tokens? [true/false]"));

        // start broadcast
        _startBroadcast();

        //
        DeployOutput memory deployOutput;

        // print users debug
        _printUsersDebug();

        // deploy config
        console.log("##### Config");
        _deployConfig(deployOutput, wbnbAddress);

        // temporarily grant roles to deployer
        deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getDeployer());
        deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getDeployer());

        // deploy asset registry
        console.log("##### Asset Registry");
        _deployAssetRegistry(deployOutput);

        // set AssetRegistry address in config
        deployOutput.config.setAddress("ASSET_REGISTRY", address(deployOutput.assetRegistry));

        // deploy staker gateway
        console.log("##### StakerGateway");
        _deployStakerGateway(deployOutput);

        //
        deployOutput.config.setAddress("STAKER_GATEWAY", address(deployOutput.stakerGateway));

        // deploy Vaults UpgradeableBeacon
        _deployKernelVaultUpgradeableBeacon(deployOutput);

        if (deployDemoTokens) {
            // deploy ERC20 demo tokens
            console.log("##### Vaults and ERC20 tokens");
            KernelVault vaultA = _deployERC20DemoToken(deployOutput, "A");
            vaultA.setDepositLimit(100 ether);

            KernelVault vaultB = _deployERC20DemoToken(deployOutput, "B");
            vaultB.setDepositLimit(100 ether);
        }

        // deploy pre-existing erc20 token vaults
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            KernelVault vault = _deployKernelVaultAndAddToAssetRegistry(deployOutput, ERC20Demo(erc20Tokens[i]));
            vault.setDepositLimit(500 ether);
        }

        // deploy wbnb vault to support native BNB
        KernelVault vaultWBNB = _deployKernelVaultAndAddToAssetRegistry(deployOutput, ERC20Demo(wbnbAddress));
        vaultWBNB.setDepositLimit(500 ether);

        console.log("");

        // grant definitive roles
        if (_getDeployer() != _getManager()) {
            deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getManager());
            deployOutput.config.revokeRole(deployOutput.config.ROLE_MANAGER(), _getDeployer());
        }

        if (_getDeployer() != _getPauser()) {
            deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getPauser());
            deployOutput.config.revokeRole(deployOutput.config.ROLE_PAUSER(), _getDeployer());
        }

        if (_getDeployer() != _getAdmin()) {
            deployOutput.config.grantRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getAdmin());
            deployOutput.config.revokeRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getDeployer());
        }

        _stopBroadcast();

        // check config
        console.log("");
        console.log("CONFIG CHECK: ", deployOutput.config.check());
    }
}
