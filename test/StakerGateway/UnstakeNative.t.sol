// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract UnstakeNativeTest is BaseTest {
    ///
    function test_UnstakeNative() public {
        //
        IERC20Demo asset = IERC20Demo(address(tokens.wbnb));
        uint256 amountToStake = 1.5 ether;

        // stake
        _startPrank(users.alice);
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);
        BaseTest.Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(initialErc20Balances.vaultAssetWBNB, amountToStake);
        assertEq(initialNativeBalances.vaultAssetWBNB, 0);

        // unstake
        stakerGateway.unstakeNative(amountToStake, "referral_id");

        // check balances
        BaseTest.Balances memory erc20Balances = _makeERC20BalanceSnapshot(asset);
        BaseTest.Balances memory nativeBalances = _makeBalanceSnapshot();

        assertEq(erc20Balances.alice, initialErc20Balances.alice);
        assertEq(nativeBalances.alice - initialNativeBalances.alice, amountToStake);

        assertEq(stakerGateway.balanceOf(address(asset), users.alice), 0);

        assertEq(erc20Balances.stakerGateway, 0);
        assertEq(nativeBalances.stakerGateway, 0);

        // assertEq(erc20Balances.assetRegistry, 0);

        assertEq(erc20Balances.vaultAssetWBNB, 0);
        assertEq(nativeBalances.vaultAssetWBNB, 0);
    }

    ///
    function test_UnstakeNative_RevertIfAmountIsGreaterThanBalance() public {
        uint256 amountToStake = 100 ether;

        // stake
        _startPrank(users.alice);
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");

        // try to unstake more than the amount staked
        _expectRevertCustomErrorWithMessage(IKernelVault.WithdrawFailed.selector, "Not enough balance to withdraw");
        stakerGateway.unstakeNative(amountToStake * 2, "");
    }

    ///
    function test_UnstakeNative_RevertIfVaultsWithdrawIsPaused() public {
        uint256 amountToStake = 100 ether;

        // Pause vault withdraw
        _pauseVaultsWithdraw();

        // stake
        _stakeNative(users.alice, amountToStake);

        _startPrank(users.alice);

        // expect revert when vault withdraw is paused
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_WITHDRAW");
        stakerGateway.unstakeNative(amountToStake, "");
    }

    ///
    function test_UnstakeNative_RevertIfProtocolIsPaused() public {
        uint256 amountToStake = 100 ether;

        // stake
        _stakeNative(users.alice, amountToStake);

        // Pause protocol
        _pauseProtocol();

        // try to unstake
        _startPrank(users.alice);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.unstakeNative(amountToStake, "");
    }
}
