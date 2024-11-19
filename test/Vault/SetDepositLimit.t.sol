// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract SetDepositLimitTest is BaseTest {
    /// test correct call of setDepositLimit by manager
    function test_SetDepositLimit() public {
        KernelVault vaultAssetA = _getVault(tokens.a);
        uint256 depositLimit = 700 ether;

        _startPrank(users.manager);

        // Set limit
        vaultAssetA.setDepositLimit(depositLimit);
        assertTrue(vaultAssetA.getDepositLimit() == depositLimit);
    }

    /// test revert call of setDepositLimit by non manager
    function test_SetDepositLimitRevertsIfNotmanager() public {
        KernelVault vaultAssetA = _getVault(tokens.a);
        uint256 depositLimit = 700 ether;

        _startPrank(users.bob);

        // Expect revert if user is non manager
        _expectRevertCustomError(IKernelConfig.NotManager.selector);
        vaultAssetA.setDepositLimit(depositLimit);
    }
}
