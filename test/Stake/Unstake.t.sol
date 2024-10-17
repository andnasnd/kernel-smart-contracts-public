// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract UnstakeTest is BaseTest {
    ///
    function test_Unstake() public {
        //
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);

        // check balances
        assertEq(initialErc20Balances.vaultAssetA, 0);

        // stake
        _stake(users.alice, asset, amountToStake);

        //
        vm.startPrank(users.alice);

        stakerGateway.unstake(address(asset), amountToStake, "referral_id");

        // check balances
        BaseTest.Balances memory erc20Balances = _makeERC20BalanceSnapshot(asset);

        assertEq(erc20Balances.alice, initialErc20Balances.alice);
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), 0);
        assertEq(erc20Balances.stakerGateway, 0);
        // assertEq(erc20Balances.assetRegistry, 0);
        assertEq(erc20Balances.vaultAssetA, 0);
    }

    ///
    function test_Unstake_RevertIfAmountIsGreaterThanBalance() public {
        ERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // try to unstake more than the amount staked
        vm.startPrank(users.alice);

        _expectRevertCustomErrorWithMessage(IKernelVault.WithdrawFailed.selector, "Not enough balance to withdraw");
        stakerGateway.unstake(address(asset), amountToStake * 2, "");
    }

    ///
    function test_Unstake_RevertIfVaultsWithdrawIsPaused() public {
        ERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // Pause vault withdraw
        _pauseVaultsWithdraw();

        vm.startPrank(users.alice);

        // expect revert when vault withdraw is paused
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.FunctionalityIsPaused.selector, "Functionality VAULTS_WITHDRAW is paused"
        );
        stakerGateway.unstake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Unstake_RevertIfProtocolIsPaused() public {
        ERC20Demo asset = tokens.a;
        uint256 amountToStake = 100 ether;

        //stake
        _mintAndStake(users.alice, asset, amountToStake);

        // Pause protocol
        _pauseProtocol();

        vm.startPrank(users.alice);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.unstake(address(asset), amountToStake, "referral_id");
    }
}
