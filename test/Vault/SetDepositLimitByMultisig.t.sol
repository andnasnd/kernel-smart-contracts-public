// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/Test.sol";

import { Safe } from "@safe-smart-account/contracts/Safe.sol";
import { OwnerManager } from "@safe-smart-account/contracts/base/OwnerManager.sol";

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";

import { SafeUtils } from "extra/SafeUtils.sol";

contract SetDepositLimitByMultisigTest is BaseTest {
    using SafeUtils for Safe;

    /// test correct setDepositLimit() call when Manager is a Multisig
    function test_SetDepositLimit_ByMultisig() public {
        uint256 newDepositLimit = 1 ether;
        KernelVault vaultAssetA = _getVault(tokens.a);

        // assert initial condition
        assertNotEq(vaultAssetA.getDepositLimit(), newDepositLimit);

        // deploy Safe
        Safe safe = _deploySafeWithRole(keccak256("MANAGER"));

        // build Safe Transaction data
        address to = address(vaultAssetA);
        bytes memory data = abi.encodeWithSelector(IKernelVault.setDepositLimit.selector, newDepositLimit);

        // propose transaction
        _startPrank(multisigOwners[0].addr);
        bytes32 safeTxHash = safe.proposeTransaction(to, data);

        // sign transaction by all other owners
        for (uint256 i = 1; i < multisigOwners.length; i++) {
            _startPrank(multisigOwners[i].addr);
            safe.approveTransactionHash(safeTxHash);
        }

        // execute approved transaction
        safe.executeApprovedTransaction(to, data);

        // assert
        assertEq(vaultAssetA.getDepositLimit(), newDepositLimit);
    }
}
