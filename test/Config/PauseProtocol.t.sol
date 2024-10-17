// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseTest } from "test/BaseTest.sol";

contract PauseProtocolTest is BaseTest {
    /// pause protocol correctly
    function test_PauseProtocol() public {
        // User with pause access
        vm.startPrank(users.pauser);
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
        vm.startPrank(users.bob);

        _expectRevertMessage(
            string.concat(
                "AccessControl: account ",
                Strings.toHexString(users.bob),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("PAUSER")))
            )
        );

        // pause protocol
        config.pauseFunctionality("PROTOCOL");
    }
}
