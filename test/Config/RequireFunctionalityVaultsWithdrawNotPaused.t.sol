// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireFunctionalityVaultsWithdrawNotPausedTest is BaseTest {
    ///
    function test_RequireFunctionalityVaultsWithdrawNotPaused() public {
        _startPrank(users.pauser);

        // pause
        config.pauseFunctionality("VAULTS_WITHDRAW");

        // revert
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_WITHDRAW");
        config.requireFunctionalityVaultsWithdrawNotPaused();
    }
}
