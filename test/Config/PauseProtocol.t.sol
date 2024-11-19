// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseTest } from "test/BaseTest.sol";

contract PauseProtocolTest is BaseTest {
    /// pause protocol correctly
    function test_PauseProtocol() public {
        // User with pause access
        _startPrank(users.pauser);
        assertFalse(config.isFunctionalityPaused("PROTOCOL"));
        assertFalse(config.isProtocolPaused());

        // pause protocol
        config.pauseFunctionality("PROTOCOL");

        // assert
        assertTrue(config.isFunctionalityPaused("PROTOCOL"));
        assertTrue(config.isProtocolPaused());
    }

    /// expect revert if user has not the right role
    function test_RevertPauseProtocolIfNotPauser() public {
        // bob doesn't have pause access
        _startPrank(users.bob);

        _expectRevertUnAuthorizedRole(users.bob, config.ROLE_PAUSER());

        // pause protocol
        config.pauseFunctionality("PROTOCOL");
    }
}
