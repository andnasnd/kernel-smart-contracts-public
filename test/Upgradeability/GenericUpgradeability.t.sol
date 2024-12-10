// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Upgrades, Options } from "@openzeppelin/upgrades/Upgrades.sol";

import { BaseTest } from "test/BaseTest.sol";
import { AssetRegistryUpgraded } from "test/mock/upgradeability/AssetRegistryUpgraded.sol"; // won't build if removed
import { KernelConfigUpgraded } from "test/mock/upgradeability/KernelConfigUpgraded.sol"; // won't build if removed
import { StakerGatewayUpgraded } from "test/mock/upgradeability/StakerGatewayUpgraded.sol"; // won't build if removed

import { IHasVersion } from "src/interfaces/IHasVersion.sol";

contract GenericUpgradeabilityTest is BaseTest {
    ///
    function test_Upgradeability() public {
        _assertUpgradable(address(config), "KernelConfigUpgraded.sol", "KernelConfig.sol");
        _assertUpgradable(address(stakerGateway), "StakerGatewayUpgraded.sol", "StakerGateway.sol");
        _assertUpgradable(address(assetRegistry), "AssetRegistryUpgraded.sol", "AssetRegistry.sol");
    }

    /// Assert upgradeable contracts are upgradeable using some mock contracts
    function _assertUpgradable(
        address proxyAddr,
        string memory contractName,
        string memory referenceContract
    )
        private
    {
        // <<< TODO: restore and catch a more precise error,
        // // try to upgrade without permission
        // _startPrank(users.alice);

        // // try _expectRevertWithUnauthorizedRole(users.alice, config.DEFAULT_ADMIN_ROLE());
        // vm.expectRevert();
        // _upgradeProxy(proxyAddr, contractName, referenceContract);
        // >>> TODO

        // assert
        assertEq(IHasVersion(proxyAddr).version(), "1.0");

        // upgrade
        Options memory opts;
        opts.referenceContract = referenceContract;
        _upgradeProxy(users.upgrader, proxyAddr, contractName, opts);

        // assert
        assertEq(IHasVersion(proxyAddr).version(), "NEXT_VERSION");
    }
}
