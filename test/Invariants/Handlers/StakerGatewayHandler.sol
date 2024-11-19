// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";

import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { AddressUtils } from "test/test-utils/AddressUtils.sol";

import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

/// Handler contract for invariant testing
/// Currently: creates stakergateway supporting ERC20 token "A", and native BNB
contract StakerGatewayHandler is CommonBase, StdCheats, StdUtils {
    IKernelConfig kernelConfig;
    IAssetRegistry assetRegistry;
    IStakerGateway stakerGateway;
    IERC20Demo asset;

    // @dev see https://book.getfoundry.sh/forge/invariant-testing#actor-management
    address[] internal actors;
    address internal currentActor;

    // tracks the Vaults' balances
    // key: ERC20 address, value: balance
    mapping(address => uint256) public vaultToBalance;

    //
    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    //
    constructor(IKernelConfig kernelConfig_, IERC20Demo asset_) {
        kernelConfig = kernelConfig_;
        assetRegistry = IAssetRegistry(kernelConfig_.getAssetRegistry());
        stakerGateway = IStakerGateway(kernelConfig_.getStakerGateway());
        asset = asset_;

        actors = AddressUtils.buildAddressArray(50, "foo-");
    }

    // Stake ERC20 token
    function stake(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        // get bounded stake amount
        amount = _getBoundedStakeAmount(amount, address(asset));

        // mint some tokens
        asset.mint(currentActor, amount);

        // approve and stake
        asset.approve(address(stakerGateway), amount);
        stakerGateway.stake(address(asset), amount, "");

        //
        vaultToBalance[address(asset)] += amount;
    }

    // Stake native bnb
    function stakeNative(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        // get bounded stake amount
        amount = _getBoundedStakeAmount(amount, kernelConfig.getWBNBAddress());

        // fund sender
        vm.deal(currentActor, amount);

        // stake
        stakerGateway.stakeNative{ value: amount }("");

        //
        vaultToBalance[kernelConfig.getWBNBAddress()] += amount;
    }

    // Unstake ERC20 token
    function unstake(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        // get bounded unstaking amount
        amount = _getBoundedUnstakeAmount(amount, address(asset), currentActor);

        // unstake
        stakerGateway.unstake(address(asset), amount, "");

        //
        vaultToBalance[address(asset)] -= amount;
    }

    // Unstake native bnb
    function unstakeNative(uint256 amount, uint256 actorIndexSeed) public useActor(actorIndexSeed) {
        // get bounded unstaking amount
        amount = _getBoundedUnstakeAmount(amount, kernelConfig.getWBNBAddress(), currentActor);

        // unstake
        stakerGateway.unstakeNative(amount, "");

        //
        vaultToBalance[kernelConfig.getWBNBAddress()] -= amount;
    }

    // Checks if {sender}'s balance is > 0 for a given asset
    // @returns uint256 sender's balance
    function _assumeSenderBalanceInVaultIsGteZero(address asset_, address sender) private view returns (uint256) {
        uint256 balanceOfSender = stakerGateway.balanceOf(asset_, sender);
        vm.assume(balanceOfSender > 0);

        return balanceOfSender;
    }

    // Calculate a random amount to stake for a given asset
    function _getBoundedStakeAmount(uint256 originalAmount, address asset_) private view returns (uint256) {
        uint256 foundryInvariantDepth = vm.envUint("FOUNDRY_INVARIANT_DEPTH");

        // check Vault deposit limit
        uint256 vaultDepositLimit = assetRegistry.getVaultDepositLimit(asset_);
        vm.assume(vaultDepositLimit >= foundryInvariantDepth);

        //
        return bound(originalAmount, 1, vaultDepositLimit / foundryInvariantDepth);
    }

    // Calculate a random amount to unstake for a given asset
    function _getBoundedUnstakeAmount(
        uint256 originalAmount,
        address asset_,
        address sender
    )
        private
        view
        returns (uint256)
    {
        // assume sender's deposit is > 0
        uint256 balanceOfSender = _assumeSenderBalanceInVaultIsGteZero(asset_, sender);

        //
        return bound(originalAmount, 1, balanceOfSender);
    }
}
