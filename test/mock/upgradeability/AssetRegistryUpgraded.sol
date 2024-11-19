// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { AssetRegistry } from "src/AssetRegistry.sol";

import { GenericUpgraded } from "test/mock/upgradeability/GenericUpgraded.sol";

/**
 * @title Mock AssetRegistry Contract to test UUPS upgradeability
 * @custom:oz-upgrades
 * @custom:oz-upgrades-from AssetRegistry
 */
contract AssetRegistryUpgraded is AssetRegistry, GenericUpgraded {
    ///
    function version() public pure override(AssetRegistry, GenericUpgraded) returns (string memory) {
        return GenericUpgraded.version();
    }
}
