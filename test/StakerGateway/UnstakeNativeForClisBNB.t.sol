// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

import { BaseTest } from "test/BaseTest.sol";
import { BaseTestWithClisBNBSupport } from "test/BaseTestWithClisBNBSupport.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract UnstakeClisBNBTest is BaseTestWithClisBNBSupport {
    ///
    function test_UnstakeClisBNB() public {
        //
        IERC20Demo asset = IERC20Demo(CLIS_BNB);
        uint256 amountToStake = 1.5 ether;

        // snapshot initial balance
        uint256 clisBNBVaultBalanceInitial = asset.balanceOf(address(clisBNBVault));
        BaseTest.Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(clisBNBVaultBalanceInitial, 0);
        assertEq(initialNativeBalances.alice, 10_000 ether);

        // stake
        _stakeClisBNB(users.alice, amountToStake);

        //
        vm.prank(users.alice);
        stakerGateway.unstakeClisBNB(amountToStake, "referral_id");

        // check balances
        uint256 clisBNBVaultBalance = asset.balanceOf(address(clisBNBVault));
        BaseTest.Balances memory nativeBalances = _makeBalanceSnapshot();

        assertEq(clisBNBVaultBalance, 0);
        assertEq(nativeBalances.alice, initialNativeBalances.alice);
    }

    ///
    function test_Unstake_RevertIfAmountIsGreaterThanBalance() public {
        uint256 amountToStake = 100 ether;

        //stake
        _stakeClisBNB(users.alice, amountToStake);

        // try to unstake more than the amount staked
        _startPrank(users.alice);

        _expectRevertCustomErrorWithMessage(IKernelVault.WithdrawFailed.selector, "Not enough balance to withdraw");
        stakerGateway.unstakeClisBNB(amountToStake * 2, "referral_id");
    }
}
