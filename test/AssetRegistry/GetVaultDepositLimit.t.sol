// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract GetVaultDepositLimitTest is BaseTest {
    ///
    function test_GetVaultDepositLimit() public view {
        // assert
        assertEq(assetRegistry.getVaultDepositLimit(address(tokens.a)), 1000 ether);
    }
}
