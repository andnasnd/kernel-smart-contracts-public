// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { KernelConfigStorage } from "src/KernelConfigStorage.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

import { BaseTest } from "test/BaseTest.sol";

contract PauseFunctionalityTest is BaseTest {
    ///
    function test_PauseFunctionality() public {
        assertFalse(config.isFunctionalityPaused("VAULTS_DEPOSIT"));

        //
        _startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        assertTrue(config.isFunctionalityPaused("VAULTS_DEPOSIT"));
    }

    /// expect revert config.pauseFunctionality() if user has not the right role
    function test_RevertPauseFunctionalitylIfNotPauser() public {
        // bob doesn't have pause access
        _startPrank(users.bob);

        // expect revert
        _expectRevertUnAuthorizedRole(users.bob, config.ROLE_PAUSER());

        config.pauseFunctionality("VAULTS_DEPOSIT");
    }

    ///
    function test_RevertPauseFunctionalitylIfFunctionalityIsInvalid() public {
        _startPrank(users.pauser);

        _expectRevertCustomErrorWithMessage(
            IKernelConfig.InvalidArgument.selector, "Functionality key NOT_EXISTING is not supported"
        );
        config.pauseFunctionality("NOT_EXISTING");
    }
}
