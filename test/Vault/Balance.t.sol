// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract BalanceTest is BaseTest {
    ///
    function test_Balance() public {
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // mint
        _mintAndStake(users.alice, asset, amountToStake);

        // assert
        assertEq(_getVault(asset).balanceOf(users.alice), amountToStake);
    }
}
