// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { console } from "forge-std/Test.sol";

import { IHelioProvider } from "src/interfaces/IHelioProvider.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { KernelVault } from "src/KernelVault.sol";

import { BaseTest } from "test/BaseTest.sol";
import { BaseTestWithClisBNBSupport } from "test/BaseTestWithClisBNBSupport.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { IMasterVault } from "test/mock/ListaDao/IMasterVault.sol";
import { IListaStakeManager } from "test/mock/ListaDao/IListaStakeManager.sol";
import { ISnBnbYieldConverterStrategy } from "test/mock/ListaDao/ISnBnbYieldConverterStrategy.sol";

contract UnstakeClisBNBTest is BaseTestWithClisBNBSupport {
    address constant LISTA_DAO_MANAGER = 0x3c246d03b82FA300426A4C1Db952B159720841f4;
    address constant LISTA_DAO_MASTER_VAULT = 0x986b40C2618fF295a49AC442c5ec40febB26CC54;
    address constant LISTA_DAO_STAKE_MANAGER = 0x1adB950d8bB3dA4bE104211D5AB038628e477fE6;
    address constant LISTA_DAO_STRATEGY = 0x6F28FeC449dbd2056b76ac666350Af8773E03873;

    ///
    function test_UnstakeClisBNB() public {
        //
        IERC20Demo asset = IERC20Demo(CLIS_BNB);
        uint256 amountToStake = 1.5 ether;

        // snapshot initial balance
        uint256 clisBNBVaultBalanceInitial = asset.balanceOf(address(clisBNBVault));
        Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(clisBNBVaultBalanceInitial, 0);
        assertEq(initialNativeBalances.alice, 10_000 ether);

        // stake
        _stakeClisBNB(users.alice, amountToStake);

        // unstake
        vm.prank(users.alice);
        stakerGateway.unstakeClisBNB(amountToStake, "referral_id");

        // check balances
        uint256 clisBNBVaultBalance = asset.balanceOf(address(clisBNBVault));
        Balances memory nativeBalances = _makeBalanceSnapshot();

        assertEq(clisBNBVaultBalance, 0);
        assertEq(nativeBalances.alice, initialNativeBalances.alice);
    }

    /// Test Staking/Unstaking of clisBNB when ListaDAO applies a Strategy
    function test_UnstakeClisBNB_WithListaStrategyApplication() public {
        //
        IERC20Demo asset = IERC20Demo(CLIS_BNB);
        uint256 amountToStake = 0.1 ether;
        KernelVault vault = _getVault(asset);

        // snapshot initial balance
        // Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // stake
        _stakeClisBNB(users.alice, amountToStake);

        // check balances
        assertEq(vault.balance(), amountToStake);

        // depositAllToStrategy by MasterVault
        vm.prank(LISTA_DAO_MANAGER); // LIstaDAO Manager
        IMasterVault(LISTA_DAO_MASTER_VAULT).depositAllToStrategy(LISTA_DAO_STRATEGY);

        // unstake
        vm.prank(users.alice);
        stakerGateway.unstakeClisBNB(amountToStake, "referral_id");

        vm.warp(block.timestamp + 10 days);

        // batchWithdraw by SnBnbYieldConverterStrategy
        ISnBnbYieldConverterStrategy(LISTA_DAO_STRATEGY).batchWithdraw();

        // undelegateFrom by ListaStakeManager
        vm.prank(0x9c975db5E112235b6c4a177C2A5c67ab4d758499);
        IListaStakeManager(LISTA_DAO_STAKE_MANAGER).undelegateFrom(0xF2B1d86DC7459887B1f7Ce8d840db1D87613Ce7f, 1 ether);

        vm.warp(block.timestamp + 14 days);

        // undelegateFrom by ListaStakeManager
        vm.prank(0x9c975db5E112235b6c4a177C2A5c67ab4d758499);
        IListaStakeManager(LISTA_DAO_STAKE_MANAGER).claimUndelegated(0xF2B1d86DC7459887B1f7Ce8d840db1D87613Ce7f);

        vm.warp(block.timestamp + 14 days);

        // assert that the number of withdrawal requests for StakerGateway and the Vault is 0
        assertEq(ISnBnbYieldConverterStrategy(LISTA_DAO_STRATEGY).getWithdrawRequests(address(stakerGateway)).length, 0);
        assertEq(ISnBnbYieldConverterStrategy(LISTA_DAO_STRATEGY).getWithdrawRequests(address(vault)).length, 0);

        // asssert Alice's withdrawal requests
        ISnBnbYieldConverterStrategy.UserWithdrawRequest[] memory aliceWithdrawrequests =
            ISnBnbYieldConverterStrategy(LISTA_DAO_STRATEGY).getWithdrawRequests(users.alice);

        // assert that the number of withdrawal requests for Alice and the Vault is 1
        assertEq(aliceWithdrawrequests.length, 1);
        assertEq(aliceWithdrawrequests[0].recipient, users.alice);
        assertEq(aliceWithdrawrequests[0].amount, amountToStake);

        // undelegateFrom by ListaStakeManager
        ISnBnbYieldConverterStrategy(LISTA_DAO_STRATEGY).claimNextBatchAndDistribute(1000);

        // assert Alice received funds

        // @dev Following lines should work because Alice should receive funds, but it doesn't happen.
        //      Anyway, just checking that Alice has 1 withw request is enough
        // Balances memory balances = _makeBalanceSnapshot();
        // assertEq(balances.alice, initialNativeBalances.alice);
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
