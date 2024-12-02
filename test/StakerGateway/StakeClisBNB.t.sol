// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { KernelVault } from "src/KernelVault.sol";

import { BaseTest } from "test/BaseTest.sol";
import { BaseTestWithClisBNBSupport } from "test/BaseTestWithClisBNBSupport.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract stakeClisBNBtest is BaseTestWithClisBNBSupport {
    ///
    function test_StakeClisBNB() public {
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
        vm.prank(users.alice);
        stakerGateway.stakeClisBNB{ value: amountToStake }("referral_id");

        // snapshot balances
        uint256 clisBNBVaultBalance = asset.balanceOf(address(clisBNBVault));
        Balances memory nativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(clisBNBVaultBalance, amountToStake);
        assertEq(nativeBalances.alice, initialNativeBalances.alice - amountToStake);
    }

    ///
    function test_StakeClisBNB_UntilReachingfDepositLimit() public {
        IERC20Demo asset = IERC20Demo(CLIS_BNB);
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        vm.prank(users.alice);
        stakerGateway.stakeClisBNB{ value: 500 ether }("referral_id");

        // bob deposits other half
        vm.prank(users.bob);
        stakerGateway.stakeClisBNB{ value: 500 ether }("referral_id");
    }

    ///
    function test_Stake_RevertIfDepositLimitIsReached() public {
        IERC20Demo asset = IERC20Demo(CLIS_BNB);
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        vm.prank(users.alice);
        stakerGateway.stakeClisBNB{ value: 500 ether }("referral_id");

        // bob tries to deposit more than half more
        uint256 amountToStake = 501 ether;

        // stake
        _expectRevertWithDepositLimitExceeded(amountToStake, vault.getDepositLimit());
        vm.prank(users.bob);
        stakerGateway.stakeClisBNB{ value: amountToStake }("referral_id");
    }
}
