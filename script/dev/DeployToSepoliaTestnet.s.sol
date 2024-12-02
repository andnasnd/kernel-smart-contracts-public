// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

import { AddressUtils } from "extra/AddressUtils.sol";
import { DeployProtocolAbstract } from "script/DeployProtocolAbstract.s.sol";

import { console } from "forge-std/Script.sol";

import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { KernelConfigUpgraded } from "test/mock/upgradeability/KernelConfigUpgraded.sol";

contract DeployToSepoliaTestnet is DeployProtocolAbstract {
    TimelockController upgraderTimelock;

    function run() external {
        // print users debug
        _printUsersDebug();

        // start broadcast
        _startBroadcast();

        // deploy Upgrader Timelock
        upgraderTimelock = _deployTimelockController(AddressUtils._buildArray1(_getAdmin()), 120);

        // deploy mock WBNB
        address wbnbAddress = _deployMockWBNB();

        // deploy Kernel
        DeployOutput memory deployOutput = _deployProtocol(wbnbAddress, _getAdmin(), new address[](0), true);

        // deploy mock token $C without adding it to Kernel
        _deployMockTokenWithoutAddingToProtocol(deployOutput, "C");

        // deploy new implementation of KernelConfig to test upgradeability
        _deployNewKernelConfigImplementationToTestUpgradeability();

        // stop broadcast
        _stopBroadcast();
    }

    ///
    function _grantDefinitiveRoles(DeployOutput memory deployOutput) internal override {
        // both admin and timelock (which admin is the proposer) can upgrade contracts
        deployOutput.config.grantRole(deployOutput.config.ROLE_UPGRADER(), address(upgraderTimelock));
        deployOutput.config.grantRole(deployOutput.config.ROLE_UPGRADER(), _getAdmin());

        // grant definitive roles
        super._grantDefinitiveRoles(deployOutput);
    }

    /// Deploy new config
    function _deployNewKernelConfigImplementationToTestUpgradeability() internal {
        console.log("");
        console.log(" ##### DEPLOY MOCK IMPLEMENTATION OF KernelConfig TO TEST UPGRADEABILITY): ");

        KernelConfigUpgraded newKernelConfig = new KernelConfigUpgraded();
        console.log("  KernelConfig new implementation deployed at: ", address(newKernelConfig));
    }

    function _deployMockTokenWithoutAddingToProtocol(DeployOutput memory deployOutput, string memory symbol) public {
        console.log("");
        console.log(" ##### DEPLOY DEMO ERC20 TOKEN (not added to AssetRegistry): ", deployOutput.config.check());

        // deploy token
        ERC20Demo token = _deployERC20DemoToken(symbol);

        console.log(string.concat("  Deployed demo ERC20 token \"", token.symbol(), "\" at "), address(token));

        // deploy Vault
        _deployKernelVault(deployOutput, token);
    }
}
