// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { KernelConfig } from "src/KernelConfig.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract RemoveAssetTest is BaseTest {
    ///
    function test_RemoveAsset() public {
        address asset = address(tokens.a);

        // tokenA is already added
        assetRegistry.getVault(asset);

        // remove asset
        vm.prank(users.admin);
        assetRegistry.removeAsset(asset);

        // reverts because asset doesn't exist anymore
        _expectRevertCustomErrorWithMessage(
            IAssetRegistry.VaultNotFound.selector,
            string.concat("Vault not found for asset ", Strings.toHexString(address(asset)))
        );
        assetRegistry.getVault(asset);
    }

    ///
    function test_RemoveAsset_RevertIfNotAdded() public {
        // tokenC is not yet added
        IERC20Demo tokenC = _deployMockERC20("C");

        // reverts because asset doesn't exist in the registry
        vm.prank(users.admin);
        _expectRevertCustomError(IAssetRegistry.AssetNotAdded.selector);
        assetRegistry.removeAsset(address(tokenC));
    }

    ///
    function test_RemoveAsset_RevertIfNotAllowedUser() public {
        address asset = address(tokens.a);

        // alice tries to remove asset, but fails
        vm.prank(users.alice);
        _expectRevertCustomError(IKernelConfig.NotAdmin.selector);
        assetRegistry.removeAsset(asset);

        // manager tries to remove asset, but fails
        vm.prank(users.manager);
        _expectRevertCustomError(IKernelConfig.NotAdmin.selector);
        assetRegistry.removeAsset(asset);
    }

    /// Removing an asset from AssetRegistry must be prevented if the KernelVault has some deposits in it
    function test_RemoveAsset_RevertIfHasDeposits() public {
        IERC20Demo asset = tokens.a;

        // stake
        _mintAndStake(users.alice, asset, 10 ether);

        // reverts when removing asset because there's something deposited
        vm.prank(users.admin);
        _expectRevertCustomError(IAssetRegistry.VaultNotEmpty.selector);
        assetRegistry.removeAsset(address(asset));
    }
}
