// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC20Demo } from "test/mock/ERC20Demo.sol";

import { BaseTest } from "test/BaseTest.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract StakeTest is BaseTest {
    ///
    function test_Stake() public {
        //
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);

        // check balances
        assertEq(initialErc20Balances.vaultAssetA, 0);

        //
        vm.startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // stake
        stakerGateway.stake(address(asset), amountToStake, "referral_id");

        // check balances
        BaseTest.Balances memory erc20Balances = _makeERC20BalanceSnapshot(asset);

        assertEq(initialErc20Balances.alice - erc20Balances.alice, amountToStake);
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), amountToStake);
        assertEq(erc20Balances.stakerGateway, 0);
        // assertEq(erc20Balances.assetRegistry, 0);
        assertEq(erc20Balances.vaultAssetA, amountToStake);
    }

    ///
    function test_Stake_RevertIfInsufficientAllowance() public {
        //
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        //
        vm.startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake / 2);

        // stake
        _expectRevertMessage("ERC20: insufficient allowance");
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfAssetWasNotAdded() public {
        uint256 amountToStake = 1.5 ether;

        // deploy new ERC20 token
        ERC20Demo asset = _deployMockERC20("foo");

        // mint
        _mintERC20(asset, users.alice, amountToStake);

        //
        vm.startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // stake
        _expectRevertCustomErrorWithMessage(
            IAssetRegistry.VaultNotFound.selector,
            string.concat("Vault not found for asset ", Strings.toHexString(address(asset)))
        );
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfDepositLimitIsReached() public {
        ERC20Demo asset = tokens.a;
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        _mintAndStake(users.alice, asset, 500 ether);

        // bob tries to deposit more than half more
        uint256 amountToStake = 501 ether;
        vm.startPrank(users.bob);

        _mintERC20(asset, users.bob, amountToStake);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // stake
        _expectRevertCustomErrorWithMessage(
            IKernelVault.DepositFailed.selector,
            string.concat(
                "Unable to deposit an amount of ",
                Strings.toString(amountToStake),
                ": limit of ",
                Strings.toString(vault.depositLimit()),
                " exceeded"
            )
        );
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfVaultsDepositIsPaused() public {
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // Pause vault deposit
        _pauseVaultsDeposit();

        // mint some tokens
        _mintERC20(asset, users.alice, amountToStake);

        vm.startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // expect revert when vault deposit is paused
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.FunctionalityIsPaused.selector, "Functionality VAULTS_DEPOSIT is paused"
        );
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfProtocolIsPaused() public {
        uint256 amountToStake = 1.5 ether;
        ERC20Demo asset = tokens.a;

        // Pause protocol
        _pauseProtocol();

        // mint some tokens
        _mintERC20(asset, users.alice, amountToStake);

        vm.startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }
}
