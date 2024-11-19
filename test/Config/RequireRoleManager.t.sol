// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract RequireRoleManagerTest is BaseTest {
    ///
    function test_RequireRoleManager() public {
        // do not revert if address has manager role
        config.requireRoleManager(users.manager);

        // expect revert if address hasn't manager role
        _expectRevertCustomError(IKernelConfig.NotManager.selector);
        config.requireRoleManager(users.alice);
    }
}
