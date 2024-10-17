// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireFunctionalityVaultsWithdrawNotPausedTest is BaseTest {
    ///
    function test_RequireFunctionalityVaultsWithdrawNotPaused() public {
        vm.startPrank(users.pauser);

        // pause
        config.pauseFunctionality("VAULTS_WITHDRAW");

        // revert
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.FunctionalityIsPaused.selector, "Functionality VAULTS_WITHDRAW is paused"
        );
        config.requireFunctionalityVaultsWithdrawNotPaused();
    }
}
