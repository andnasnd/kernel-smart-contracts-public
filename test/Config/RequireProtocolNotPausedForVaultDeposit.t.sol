// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireProtocolNotPausedForVaultDepositTest is BaseTest {
    /// Expect revert when protocol is paused
    function test_RequireProtocolNotPausedForVaultsDeposit() public {
        vm.startPrank(users.pauser);

        // pause protocol
        config.pauseFunctionality("PROTOCOL");

        // expect revert
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        config.requireFunctionalityVaultsDepositNotPaused();
    }
}
