// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Upgrades, Options } from "@openzeppelin/upgrades/Upgrades.sol";
import { KernelConfigUpgraded } from "test/mock/upgradeability/KernelConfigUpgraded.sol"; // won't build if removed

import { BaseTest } from "test/BaseTest.sol";

contract V06UpgradeabilityTest is BaseTest {
    address internal upgraderTimelock = 0xc34C665264DAC8a589F240684aFd18f52d98C602; // Mainnet Upgrader Timelock

    ///
    function setUp() public virtual override {
        // setup forking mainnet
        _forkBscMainnetPriorToFixDonationBug();
    }

    ///
    function test_V06Upgradeability_StakerGateway() public {
        Options memory opts;
        opts.referenceBuildInfoDir = "./builds/v1.0/";
        opts.referenceContract = "v1.0:StakerGateway";

        address stakerGatewayProxy = 0xb32dF5B33dBCCA60437EC17b27842c12bFE83394;

        _upgradeProxy(upgraderTimelock, stakerGatewayProxy, "StakerGateway.sol", opts);
    }

    ///
    function test_V06Upgradeability_KernelVault() public {
        Options memory opts;
        opts.referenceBuildInfoDir = "./builds/v1.0/";
        opts.referenceContract = "v1.0:KernelVault";

        address kernelVaultBeacon = 0xA026462C57BE1bDd668dE6ce2F8Ab2E332c112fE;

        _upgradeBeacon(upgraderTimelock, kernelVaultBeacon, "KernelVault.sol", opts);
    }
}
