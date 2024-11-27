// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";

contract DirectVaultAccessTest is BaseTest {
    /// Expect revert when calling deposit() not from StakerGateway
    function test_RevertWhenDepositAccessedDirectly() public {
        address[3] memory allUsers = [address(users.alice), address(users.manager), address(users.admin)];
        KernelVault vaultAssetA = _getVault(tokens.a);

        for (uint256 i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];

            _startPrank(user);

            _expectRevertWithUnauthorizedCaller(user);
            vaultAssetA.deposit(1 ether, address(vaultAssetA));
        }
    }

    /// Expect revert when calling withdraw() not from StakerGateway
    function test_RevertWhenWithdrawAccessedDirectly() public {
        address[3] memory allUsers = [address(users.alice), address(users.manager), address(users.admin)];
        KernelVault vaultAssetA = _getVault(tokens.a);

        for (uint256 i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];

            _startPrank(user);

            _expectRevertWithUnauthorizedCaller(user);
            vaultAssetA.withdraw(1 ether, address(vaultAssetA), true);
        }
    }
}
