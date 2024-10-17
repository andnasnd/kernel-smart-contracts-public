// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { BaseTest } from "test/BaseTest.sol";

contract PauseFunctionalityTest is BaseTest {
    ///
    function test_PauseFunctionality() public {
        assertFalse(config.isFunctionalityPaused("VAULTS_DEPOSIT"));

        //
        vm.startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        assertTrue(config.isFunctionalityPaused("VAULTS_DEPOSIT"));
    }

    /// expect revert config.pauseFunctionality() if user has not the right role
    function test_RevertPauseFunctionalitylIfNotPauser() public {
        // bob doesn't have pause access
        vm.startPrank(users.bob);

        // expect revert
        _expectRevertMessage(
            string.concat(
                "AccessControl: account ",
                Strings.toHexString(users.bob),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("PAUSER")))
            )
        );

        config.pauseFunctionality("VAULTS_DEPOSIT");
    }

    ///
    function test_RevertPauseFunctionalitylIfFunctionalityIsInvalid() public {
        vm.startPrank(users.pauser);

        _expectRevertCustomErrorWithMessage(
            IKernelConfig.InvalidArgument.selector, "Functionality key NOT_EXISTING is not supported"
        );
        config.pauseFunctionality("NOT_EXISTING");
    }
}
