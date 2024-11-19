// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { KernelVault } from "src/KernelVault.sol";

import { BaseTest } from "test/BaseTest.sol";
import { ArrayUtils } from "test/test-utils/ArrayUtils.sol";

contract GetAssetsTest is BaseTest {
    using ArrayUtils for address[];

    ///
    function test_GetAssets() public {
        // deploy a new AssetRegistry
        _deployWithoutVaults();
        // assert initial condition

        address[] memory assets = assetRegistry.getAssets();
        assertEq(assets.length, 0);

        // add 1 asset
        KernelVault vaultA = _deployKernelVault(tokens.a, 1000 ether);
        _startPrank(users.admin);
        assetRegistry.addAsset(address(vaultA));
        vm.stopPrank();

        // assert
        assets = assetRegistry.getAssets();
        assertEq(assets.length, 1);

        _assertAddressArrayEq(assets, ArrayUtils.buildAddressArray().add(address(tokens.a)));

        // add 1 asset
        KernelVault vaultB = _deployKernelVault(tokens.b, 1000 ether);
        _startPrank(users.admin);
        assetRegistry.addAsset(address(vaultB));
        vm.stopPrank();

        // assert
        assets = assetRegistry.getAssets();
        assertEq(assets.length, 2);

        _assertAddressArrayEq(assets, ArrayUtils.buildAddressArray().add(address(tokens.a)).add(address(tokens.b)));

        // remove 1 asset
        _startPrank(users.admin);
        assetRegistry.removeAsset(address(tokens.a));
        vm.stopPrank();

        // assert
        assets = assetRegistry.getAssets();
        assertEq(assets.length, 1);
        _assertAddressArrayEq(assets, ArrayUtils.buildAddressArray().add(address(tokens.b)));

        // remove 1 asset
        _startPrank(users.admin);
        assetRegistry.removeAsset(address(tokens.b));
        vm.stopPrank();

        // assert
        assets = assetRegistry.getAssets();
        assertEq(assets.length, 0);
    }
}
