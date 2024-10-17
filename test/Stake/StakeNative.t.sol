// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseTest } from "test/BaseTest.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract StakeNativeTest is BaseTest {
    ///
    function test_StakeNative() public {
        //
        ERC20Demo asset = ERC20Demo(address(tokens.wbnb));
        uint256 amountToStake = 1.5 ether;

        // snapshot initial balance
        BaseTest.Balances memory initialErc20Balances = _makeERC20BalanceSnapshot(asset);
        BaseTest.Balances memory initialNativeBalances = _makeBalanceSnapshot();

        // check balances
        assertEq(initialErc20Balances.vaultAssetWBNB, 0);
        assertEq(initialNativeBalances.vaultAssetWBNB, 0);

        //
        vm.startPrank(users.alice);

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
        vm.startPrank(users.alice);

        // stake
        _expectRevertCustomErrorWithMessage(
            IAssetRegistry.VaultNotFound.selector,
            string.concat("Vault not found for asset ", Strings.toHexString(address(tokens.wbnb)))
        );
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfDepositLimitIsReached() public {
        ERC20Demo asset = ERC20Demo(address(tokens.wbnb));
        KernelVault vault = _getVault(asset);

        // set depositLimit
        _setDepositLimit(vault, 1000 ether);

        // alice deposits half of available limit
        vm.startPrank(users.alice);
        stakerGateway.stakeNative{ value: 500 ether }("referral_id");

        // bob tries to deposit more than half more
        vm.startPrank(users.bob);
        uint256 amountToStake = 501 ether;

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
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfVaultsDepositIsPaused() public {
        uint256 amountToStake = 1.5 ether;

        // Pause vault deposit
        _pauseVaultsDeposit();

        //
        vm.startPrank(users.alice);

        // expect revert when vault deposit is paused
        _expectRevertCustomErrorWithMessage(
            IKernelConfig.FunctionalityIsPaused.selector, "Functionality VAULTS_DEPOSIT is paused"
        );
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }

    ///
    function test_StakeNative_RevertIfProtocolIsPaused() public {
        uint256 amountToStake = 1.5 ether;

        // Pause protocol
        _pauseProtocol();

        vm.startPrank(users.alice);

        // expect revert when protocol is paused
        _expectRevertCustomError(IKernelConfig.ProtocolIsPaused.selector);
        stakerGateway.stakeNative{ value: amountToStake }("referral_id");
    }
}
