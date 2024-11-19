// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { KernelVault } from "src/KernelVault.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract BalanceOfTest is BaseTest {
    ///
    function test_BalanceOf() public {
        //
        uint256 amountToStake = 1.5 ether;
        IERC20Demo asset = tokens.a;

        // check balances
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), 0);

        // mint some tokens
        _mintAndStake(users.alice, asset, amountToStake);

        // check balances
        assertEq(stakerGateway.balanceOf(address(asset), users.alice), amountToStake);
    }
}
