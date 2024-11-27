// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract UnpauseProtocolTest is BaseTest {
    /// unpause protocol correctly
    function test_UnpauseProtocol() public {
        // pause
        _startPrank(users.pauser);
        config.pauseFunctionality("PROTOCOL");
        assertTrue(config.isFunctionalityPaused("PROTOCOL", false));
        assertTrue(config.isProtocolPaused());

        // unpause
        _startPrank(users.admin);
        config.unpauseFunctionality("PROTOCOL");
        assertFalse(config.isFunctionalityPaused("PROTOCOL", false));
        assertFalse(config.isProtocolPaused());
    }

    /// expect revert if user has not the right role
    function test_RevertUnpauseProtocolIfNotAdmin() public {
        // Alice is not Admin
        _startPrank(users.alice);

        // expect revert
        _expectRevertWithUnauthorizedRole(users.alice, 0x00);

        config.unpauseFunctionality("PROTOCOL");
    }
}
