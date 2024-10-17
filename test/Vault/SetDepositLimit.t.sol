// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract SetDepositLimitTest is BaseTest {
    /// test correct call of setDepositLimit by manager
    function test_SetDepositLimit() public {
        KernelVault vaultAssetA = _getVault(tokens.a);
        uint256 depositLimit = 700 ether;

        vm.startPrank(users.manager);

        // Set limit
        vaultAssetA.setDepositLimit(depositLimit);
        assertTrue(vaultAssetA.depositLimit() == depositLimit);
    }

    /// test revert call of setDepositLimit by non manager
    function test_SetDepositLimitRevertsIfNotmanager() public {
        KernelVault vaultAssetA = _getVault(tokens.a);
        uint256 depositLimit = 700 ether;

        vm.startPrank(users.bob);

        // Expect revert if user is non manager
        _expectRevertCustomError(IKernelConfig.NotManager.selector);
        vaultAssetA.setDepositLimit(depositLimit);
    }
}
