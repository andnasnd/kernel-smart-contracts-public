// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { ERC20WithTranferTaxDemo } from "test/mock/ERC20WithTranferTaxDemo.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract StakeTest is BaseTest {
    ///
    function test_Stake() public {
        //
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);

        // check balances
        assertEq(initialErc20Balances.vaultAssetA, 0);

        //
        _startPrank(users.alice);

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
    function test_Stake_UntilReachingfDepositLimit() public {
        IERC20Demo asset = tokens.a;
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        _mintAndStake(users.alice, asset, 500 ether);

        // bob deposits other half
        _mintAndStake(users.bob, asset, 500 ether);
    }

    ///
    function test_Stake_ERC20WithTransferTax() public {
        ERC20WithTranferTaxDemo asset = _deployMockERC20WithTranferTaxDemo("a", 1000);
        KernelVault vault = _deployKernelVault(asset, 1000 ether);

        _startPrank(users.admin);
        assetRegistry.addAsset(address(vault));
        vm.stopPrank();

        // alice stakes
        _mintAndStake(users.alice, asset, 100 ether);

        //
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), 90 ether);
    }

    ///
    function test_Stake_RevertIfInsufficientAllowance() public {
        //
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // mint some tokens
        _mintERC20(asset, users.alice, 10 ether);

        //
        _startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake / 2);

        // stake
        bytes memory errorData = abi.encodeWithSelector(
            IERC20Errors.ERC20InsufficientAllowance.selector, address(stakerGateway), amountToStake / 2, amountToStake
        );
        vm.expectRevert(errorData);
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfAssetWasNotAdded() public {
        uint256 amountToStake = 1.5 ether;

        // deploy new ERC20 token
        IERC20Demo asset = _deployMockERC20("foo");

        // mint
        _mintERC20(asset, users.alice, amountToStake);

        //
        _startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // stake
        _expectRevertWithVaultNotFound(address(asset));
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfDepositLimitIsReached() public {
        IERC20Demo asset = tokens.a;
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        _mintAndStake(users.alice, asset, 500 ether);

        // bob tries to deposit more than half more
        uint256 amountToStake = 501 ether;
        _startPrank(users.bob);

        _mintERC20(asset, users.bob, amountToStake);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // stake
        _expectRevertWithDepositLimitExceeded(amountToStake, vault.getDepositLimit());
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfVaultsDepositIsPaused() public {
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // Pause vault deposit
        _pauseVaultsDeposit();

        // mint some tokens
        _mintERC20(asset, users.alice, amountToStake);

        _startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // expect revert when vault deposit is paused
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_DEPOSIT");
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfProtocolIsPaused() public {
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // Pause protocol
        _pauseProtocol();

        // mint some tokens
        _mintERC20(asset, users.alice, amountToStake);

        _startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), amountToStake);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.stake(address(asset), amountToStake, "referral_id");
    }

    ///
    function test_Stake_RevertIfAmountIsZero() public {
        IERC20Demo asset = tokens.a;

        _startPrank(users.alice);

        // approve ERC20
        asset.approve(address(stakerGateway), 1);

        // expect revert when protocol is paused
        _expectRevertCustomErrorWithMessage(IStakerGateway.InvalidArgument.selector, "Invalid zero amount");
        stakerGateway.stake(address(asset), 0, "referral_id");
    }
}
