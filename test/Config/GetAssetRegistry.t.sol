// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract GetAssetRegistryTest is BaseTest {
    /// retrieve correctly config.getAssetRegistry()
    function test_GetAssetRegistry() public view {
        assertEq(config.getAssetRegistry(), address(assetRegistry));
    }
}
