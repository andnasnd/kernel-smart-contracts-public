// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract GetVaultBalanceTest is BaseTest {
    ///
    function test_GetVaultBalance() public {
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // mint
        _mintAndStake(users.alice, asset, amountToStake);

        // assert
        assertEq(assetRegistry.getVaultBalance(address(asset)), amountToStake);
    }
}
