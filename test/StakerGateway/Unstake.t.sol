// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract UnstakeTest is BaseTest {
    ///
    function test_Unstake() public {
        //
        IERC20Demo asset = tokens.a;
        uint256 amountToStake = 1.5 ether;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        // snapshot initial balance
        BalancesERC20 memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);
        BalancesVaults memory initialVaultsBalances = _makeVaultsBalanceSnapshot();

        // check balances
        assertEq(initialVaultsBalances.vaultAssetA, 0);

        // stake
        _stake(users.alice, asset, amountToStake);

        //
        _startPrank(users.alice);

        stakerGateway.unstake(address(asset), amountToStake, "referral_id");

        // check balances
        BalancesERC20 memory erc20Balances = _makeERC20BalanceSnapshot(asset);
        BalancesVaults memory vaultsBalances = _makeVaultsBalanceSnapshot();

        assertEq(erc20Balances.alice, initialErc20Balances.alice);
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), 0);
        assertEq(erc20Balances.stakerGateway, 0);
        assertEq(vaultsBalances.vaultAssetA, 0);
    }

    ///
    function test_Unstake_RevertIfAmountIsGreaterThanBalance() public {
        IERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // try to unstake more than the amount staked
        _startPrank(users.alice);

        _expectRevertCustomErrorWithMessage(IKernelVault.WithdrawFailed.selector, "Not enough balance to withdraw");
        stakerGateway.unstake(address(asset), amountToStake * 2, "");
    }

    ///
    function test_Unstake_RevertIfVaultsWithdrawIsPaused() public {
        IERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // Pause vault withdraw
        _pauseVaultsWithdraw();

        _startPrank(users.alice);

        // expect revert when vault withdraw is paused
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_WITHDRAW");
        stakerGateway.unstake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Unstake_RevertIfProtocolIsPaused() public {
        IERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // Pause protocol
        _pauseProtocol();

        _startPrank(users.alice);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.unstake(address(asset), amountToStake, "referral_id");
    }
}
