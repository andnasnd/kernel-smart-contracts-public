// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseTest } from "test/BaseTest.sol";

contract UnpauseFunctionalityTest is BaseTest {
    ///
    function test_UnpauseFunctionality() public {
        // pause
        vm.startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        assertTrue(config.isFunctionalityPaused("VAULTS_DEPOSIT"));

        // unpause
        vm.startPrank(users.admin);
        config.unpauseFunctionality("VAULTS_DEPOSIT");
        assertFalse(config.isFunctionalityPaused("VAULTS_DEPOSIT"));
    }

    /// expect revert config.unpauseFunctionality() if user has not the right role
    function test_RevertUnpauseFunctionalitylIfNotAdmin() public {
        vm.startPrank(users.alice);

        // expect revert
        _expectRevertMessage(
            string.concat(
                "AccessControl: account ",
                Strings.toHexString(users.alice),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );

        config.unpauseFunctionality("VAULTS_DEPOSIT");
    }

    ///
    function test_RevertUnpauseFunctionalitylIfFunctionalityIsInvalid() public {
        vm.startPrank(users.admin);

        // expect revert
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.InvalidArgument.selector, "Functionality key NOT_EXISTING is not supported"
        );
        config.unpauseFunctionality("NOT_EXISTING");
    }
}
