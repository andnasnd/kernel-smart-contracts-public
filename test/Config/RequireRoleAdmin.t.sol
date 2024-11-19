// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireRoleAdminTest is BaseTest {
    ///
    function test_RequireRoleAdmin() public {
        // do not revert if address has admin role
        config.requireRoleAdmin(users.admin);

        // expect revert if address hasn't admin role
        _expectRevertCustomError(IKernelConfig.NotAdmin.selector);
        config.requireRoleAdmin(users.alice);
    }
}
