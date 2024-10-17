// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { KernelVault } from "src/KernelVault.sol";

contract AssetTest is BaseTest {
    /// test KernelVault balance
    function test_Balance() public {
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // mint
        _mintAndStake(users.alice, asset, amountToStake);

        // assert
        assertEq(_getVault(asset).balanceOf(users.alice), amountToStake);
    }

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
