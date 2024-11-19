// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Safe } from "@safe-smart-account/contracts/Safe.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

import { SafeUtils } from "extra/SafeUtils.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";

contract ProposeMultisigTransaction is BaseScript {
    using SafeUtils for Safe;

    /**
     * @dev this script is for dev purposes only, just to test if a transaction proposal can be created
     * @dev it accepts a Vault's address and increments the deposit limit by 1
     */
    function run() external {
        address safeAddress = _promptAddress("Enter Safe account: ");
        address target = _promptAddress("Enter Vault address: ");

        // @dev for dev purposes only
        uint256 newDepositLimit = IKernelVault(target).getDepositLimit() + 1;
        bytes memory data = abi.encodeWithSelector(IKernelVault.setDepositLimit.selector, newDepositLimit);

        // get deployed Safe
        Safe safe = SafeUtils.getDeployedSafe(safeAddress);

        // get Transaction Hash (debug purposes)
        bytes32 safeTxHash = safe.getTransactionHash(target, data);
        console.log("safeTxHash");
        console.logBytes32(safeTxHash);

        //
        _startBroadcast();

        // 1. Propose a transaction by one owner
        safe.proposeTransaction(target, data);

        // 2. Approve the transaction by another owner
        // safe.approveTransactionHash(safeTxHash);

        // 3. Once all the owners have approved the transaction, anyone can execute it
        // safe.executeApprovedTransaction(target, data);

        //
        _stopBroadcast();
    }
}
