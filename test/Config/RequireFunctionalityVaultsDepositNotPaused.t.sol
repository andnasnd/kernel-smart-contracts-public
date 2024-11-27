// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireFunctionalityVaultsDepositNotPausedTest is BaseTest {
    ///
    function test_requireFunctionalityVaultsDepositNotPaused() public {
        _startPrank(users.pauser);

        // pause
        config.pauseFunctionality("VAULTS_DEPOSIT");

        // revert
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_DEPOSIT");
        config.requireFunctionalityVaultsDepositNotPaused();
    }
}
