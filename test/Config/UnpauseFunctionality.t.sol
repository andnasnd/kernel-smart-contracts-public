// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseTest } from "test/BaseTest.sol";

contract UnpauseFunctionalityTest is BaseTest {
    ///
    function test_UnpauseFunctionality() public {
        // pause
        _startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        assertTrue(config.isFunctionalityPaused("VAULTS_DEPOSIT"));

        // unpause
        _startPrank(users.admin);
        config.unpauseFunctionality("VAULTS_DEPOSIT");
        assertFalse(config.isFunctionalityPaused("VAULTS_DEPOSIT"));
    }

    /// expect revert config.unpauseFunctionality() if user has not the right role
    function test_RevertUnpauseFunctionalitylIfNotAdmin() public {
        _startPrank(users.alice);

        // expect revert
        _expectRevertUnAuthorizedRole(users.alice, 0x00);

        config.unpauseFunctionality("VAULTS_DEPOSIT");
    }

    ///
    function test_RevertUnpauseFunctionalitylIfFunctionalityIsInvalid() public {
        _startPrank(users.admin);

        // expect revert
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.InvalidArgument.selector, "Functionality key NOT_EXISTING is not supported"
        );
        config.unpauseFunctionality("NOT_EXISTING");
    }
}
