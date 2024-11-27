// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract StakeNativeTest is BaseTest {
    ///
    function test_StakeNative() public {
        //
        IERC20Demo asset = IERC20Demo(address(tokens.wbnb));
        uint256 amountToStake = 1.5 ether;

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);
        BaseTest.Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(initialErc20Balances.vaultAssetWBNB, 0);
        assertEq(initialNativeBalances.vaultAssetWBNB, 0);

        //
        _startPrank(users.alice);

        // stake
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");

        // check balances
        BaseTest.Balances memory erc20Balances = _makeERC20BalanceSnapshot(asset);
        BaseTest.Balances memory nativeBalances = _makeBalanceSnapshot();

        assertEq(initialNativeBalances.alice - nativeBalances.alice, amountToStake);

        assertEq(stakerGateway.balanceOf(address(asset), users.alice), amountToStake);

        assertEq(erc20Balances.stakerGateway, 0);
        assertEq(nativeBalances.stakerGateway, 0);

        // assertEq(erc20Balances.assetRegistry, 0);

        assertEq(erc20Balances.vaultAssetWBNB, amountToStake);
        assertEq(nativeBalances.vaultAssetWBNB, 0);
    }

    ///
    function test_StakeNative_RevertIfWBNBWasNotAdded() public {
        // overwrite deployed Config
        _deployWithoutVaults();

        uint256 amountToStake = 1.5 ether;

        //
        _startPrank(users.alice);

        // stake
        _expectRevertWithVaultNotFound(address(tokens.wbnb));
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfDepositLimitIsReached() public {
        IERC20Demo asset = IERC20Demo(address(tokens.wbnb));
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        _startPrank(users.alice);
        stakerGateway.stakeNative{ value: 500 ether }("referral_id");

        // bob tries to deposit more than half more
        _startPrank(users.bob);
        uint256 amountToStake = 501 ether;

        // stake
        _expectRevertWithDepositLimitExceeded(amountToStake, vault.getDepositLimit());
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfVaultsDepositIsPaused() public {
        uint256 amountToStake = 1.5 ether;

        // Pause vault deposit
        _pauseVaultsDeposit();

        //
        _startPrank(users.alice);

        // expect revert when vault deposit is paused
        _expectRevertCustomErrorWithMessage(IKernelConfig.FunctionalityIsPaused.selector, "VAULTS_DEPOSIT");
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfProtocolIsPaused() public {
        uint256 amountToStake = 1.5 ether;

        // Pause protocol
        _pauseProtocol();

        _startPrank(users.alice);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    /// Sending BNB should be allowed only from Vault when staking native BNB
    function test_StakeNative_RevertIfBNBIsSentDirectlyToStakerGateway() public {
        _startPrank(users.alice);

        // try to send BNB directly
        _expectRevertCustomError(IStakerGateway.CannotReceiveNativeTokens.selector);
        (bool sent,) = address(stakerGateway).call{ value: 1 ether }("");

        // this require works even if it's counter-intuitive
        // if transfer reverts, {sent} is true
        require(sent == true, "Transferring BNB directly should not be allowed");
    }

    ///
    function test_StakeNative_RevertIfMsgValueIsZero() public {
        _startPrank(users.alice);

        // expect revert when msg.value is 0
        _expectRevertCustomErrorWithMessage(IStakerGateway.InvalidArgument.selector, "Invalid zero amount");
        stakerGateway.stakeNative("referral_id");
    }
}
