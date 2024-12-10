// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { KernelConfig } from "src/KernelConfig.sol";

import { GenericUpgraded } from "test/mock/upgradeability/GenericUpgraded.sol";

/**
 * @title Mock KernelConfig Contract to test UUPS upgradeability
 */
contract KernelConfigUpgraded is KernelConfig, GenericUpgraded {
    ///
    function version() public pure override(KernelConfig, GenericUpgraded) returns (string memory) {
        return GenericUpgraded.version();
    }
}
