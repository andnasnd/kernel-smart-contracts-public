// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";

contract AssetTest is BaseTest {
    /// test getAsset()
    function test_GetAsset() public view {
        KernelVault vaultAssetA = _getVault(tokens.a);
        assertEq(vaultAssetA.getAsset(), address(tokens.a));
    }

    /// test getDecimals()
    function test_GetDecimals() public view {
        assertEq(_getVault(tokens.a).getDecimals(), 18);
    }
}
