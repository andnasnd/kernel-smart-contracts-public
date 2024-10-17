// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract UnpauseProtocolTest is BaseTest {
    /// unpause protocol correctly
    function test_UnpauseProtocol() public {
        // pause
        vm.startPrank(users.pauser);
        config.pauseFunctionality("PROTOCOL");
        assertTrue(config.isFunctionalityPaused("PROTOCOL"));

        // unpause
        vm.startPrank(users.admin);
        config.unpauseFunctionality("PROTOCOL");
        assertFalse(config.isFunctionalityPaused("PROTOCOL"));
    }

    /// expect revert if user has not the right role
    function test_RevertUnpauseProtocolIfNotAdmin() public {
        // Alice is not Admin
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

        config.unpauseFunctionality("PROTOCOL");
    }
}
