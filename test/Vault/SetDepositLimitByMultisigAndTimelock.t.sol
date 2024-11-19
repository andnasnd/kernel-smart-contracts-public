// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/Test.sol";

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { Safe } from "@safe-smart-account/contracts/Safe.sol";
import { OwnerManager } from "@safe-smart-account/contracts/base/OwnerManager.sol";

import { BaseTest } from "test/BaseTest.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";

import { AddressUtils } from "extra/AddressUtils.sol";
import { SafeUtils } from "extra/SafeUtils.sol";

contract SetDepositLimitByMultisigAndTimelockTest is BaseTest {
    using SafeUtils for Safe;

    /// test correct setDepositLimit() call when Manager is a Multisig
    function test_SetDepositLimit_ByMultisig() public {
        uint256 newDepositLimit = 1 ether;
        KernelVault vaultAssetA = _getVault(tokens.a);

        // assert initial condition
        assertNotEq(vaultAssetA.getDepositLimit(), newDepositLimit);

        // deploy Safe
        Safe safe = _deploySafe();

        // deploy timelock
        TimelockController timelockController =
            _deployTimelockControllerWithProposers(AddressUtils._buildArray1(address(safe)));

        _grantRole(config, keccak256("MANAGER"), address(timelockController));

        // build Timelock parameters

        address target = address(vaultAssetA);
        uint256 value = 0;
        bytes memory tcData = abi.encodeWithSelector(IKernelVault.setDepositLimit.selector, newDepositLimit);
        bytes32 predecessor = bytes32(0);
        bytes32 salt = bytes32(0);
        uint256 delay = 3600;

        address to = address(timelockController);
        bytes memory data = _buildDataForMultisig(target, value, tcData, predecessor, salt, delay);

        // execute Safe Transaction
        _executeTransactionThroughProposalAndSingleApprovals(safe, multisigOwners, to, data);

        // execute Timelock ready operation
        vm.warp(3601);
        timelockController.execute(target, value, tcData, predecessor, salt);

        // assert
        assertEq(vaultAssetA.getDepositLimit(), newDepositLimit);
    }

    ///
    function _buildDataForMultisig(
        address target,
        uint256 value,
        bytes memory tcData,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    )
        private
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TimelockController.schedule.selector, target, value, tcData, predecessor, salt, delay
        );
    }
}
