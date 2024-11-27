// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { ERC20Demo } from "test/mock/ERC20Demo.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

import { KernelVault } from "src/KernelVault.sol";

abstract contract DeployProtocolAbstract is BaseScript {
    /**
     * @notice Deploy the whole protocl in testnet, including mock ERC20 tokens
     * @param wbnbAddress mandatory, address of the WBNB contract to support native staking/unstaking
     * @param erc20Tokens pre-existing ERC20 tokens to add in the asset registry
     * @param deployDemoTokens if true, deploy demo ERC20 tokens
     */
    function _deployProtocol(
        address wbnbAddress,
        address[] memory erc20Tokens,
        bool deployDemoTokens
    )
        internal
        returns (DeployOutput memory)
    {
        require(wbnbAddress != address(0), "WBNB address is mandatory");

        //
        DeployOutput memory deployOutput;

        // print users debug
        _printUsersDebug();

        // deploy config
        _deployConfig(deployOutput, wbnbAddress);

        // temporarily grant roles to deployer
        deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getDeployer());
        deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getDeployer());

        // deploy asset registry
        _deployAssetRegistry(deployOutput);

        // set AssetRegistry address in config
        deployOutput.config.setAddress("ASSET_REGISTRY", address(deployOutput.assetRegistry));

        // deploy staker gateway
        _deployStakerGateway(deployOutput);

        //
        deployOutput.config.setAddress("STAKER_GATEWAY", address(deployOutput.stakerGateway));

        // deploy Vaults UpgradeableBeacon
        _deployKernelVaultUpgradeableBeacon(deployOutput);

        // (optionally) deploy ERC20 demo tokens
        if (deployDemoTokens) {
            console.log("");
            console.log("##### ERC20 Demo tokens and relative Vaults");
            KernelVault vaultA = _deployERC20DemoTokenAndAddVaultTOAssetRegistry(deployOutput, "A");
            vaultA.setDepositLimit(100 ether);

            KernelVault vaultB = _deployERC20DemoTokenAndAddVaultTOAssetRegistry(deployOutput, "B");
            vaultB.setDepositLimit(100 ether);
        }

        // deploy pre-existing erc20 token vaults
        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            KernelVault vault = _deployKernelVaultAndAddToAssetRegistry(deployOutput, ERC20Demo(erc20Tokens[i]));
            vault.setDepositLimit(500 ether);
        }

        // deploy WBNB vault to support native BNB
        KernelVault vaultWBNB = _deployKernelVaultAndAddToAssetRegistry(deployOutput, ERC20Demo(wbnbAddress));
        vaultWBNB.setDepositLimit(500 ether);

        //
        console.log("");

        // grant definitive roles
        _grantDefinitiveRoles(deployOutput);

        // check config
        console.log("");
        console.log(" ##### CONFIG CHECK: ", deployOutput.config.check());

        // return
        return deployOutput;
    }

    /// @notice Grant roles defined in .env
    /// @dev Override if necessary, remember that the deployer was granted with all the roles
    function _grantDefinitiveRoles(DeployOutput memory deployOutput) internal virtual {
        if (_getDeployer() != _getManager()) {
            deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getManager());
            deployOutput.config.revokeRole(deployOutput.config.ROLE_MANAGER(), _getDeployer());
        }

        if (_getDeployer() != _getPauser()) {
            deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getPauser());
            deployOutput.config.revokeRole(deployOutput.config.ROLE_PAUSER(), _getDeployer());
        }

        // role UPGRADER is not granted to anyone
        // if (_getDeployer() != _getUpgrader()) {
        //     deployOutput.config.grantRole(deployOutput.config.ROLE_UPGRADER(), _getUpgrader());
        //     deployOutput.config.revokeRole(deployOutput.config.ROLE_UPGRADER(), _getDeployer());
        // }

        if (_getDeployer() != _getAdmin()) {
            deployOutput.config.grantRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getAdmin());
            deployOutput.config.revokeRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getDeployer());
        }
    }
}
