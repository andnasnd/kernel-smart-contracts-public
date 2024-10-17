// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { KernelVault } from "src/KernelVault.sol";
import { KernelConfig } from "src/KernelConfig.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

import { BaseTest } from "test/BaseTest.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";

contract AddAssetTest is BaseTest {
    ///
    function test_AddAsset() public {
        // deploy a new token and corresponding vault
        ERC20Demo asset = _deployMockERC20("C");
        KernelVault vaultC = _deployVault(asset, address(config), 101 ether);

        // reverts because asset has not been added yet
        _expectRevertCustomErrorWithMessage(
            IAssetRegistry.VaultNotFound.selector,
            string.concat("Vault not found for asset ", Strings.toHexString(address(asset)))
        );
        assetRegistry.getVault(address(asset));

        // add vault for asset
        vm.prank(users.manager);
        assetRegistry.addAsset(address(vaultC));

        // assert vaultC is added against asset
        assertEq(assetRegistry.getVault(address(asset)), address(vaultC));
    }

    ///
    function test_AddAsset_RevertIfAlreadyAdded() public {
        // deploy a new vault for tokenA
        KernelVault newVaultA = _deployVault(tokens.a, address(config), 101 ether);

        // reverts because vault for tokenA has already been added
        vm.prank(users.manager);
        _expectRevertCustomError(IAssetRegistry.AssetAlreadyAdded.selector);
        assetRegistry.addAsset(address(newVaultA));
    }

    ///
    function test_AddAsset_RevertIfNotAllowedUser() public {
        ERC20Demo asset = _deployMockERC20("C");
        KernelVault vaultC = _deployVault(asset, address(config), 101 ether);

        // alice tries to add asset asset, but fails
        vm.prank(users.alice);
        _expectRevertCustomError(IKernelConfig.NotManager.selector);
        assetRegistry.addAsset(address(vaultC));

        // admin tries to add asset asset, but fails
        vm.prank(users.admin);
        _expectRevertCustomError(IKernelConfig.NotManager.selector);
        assetRegistry.addAsset(address(vaultC));
    }
}
