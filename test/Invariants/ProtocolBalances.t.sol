// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { StakerGatewayHandler } from "test/Invariants/Handlers/StakerGatewayHandler.sol";

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

/// Invariant tests on contracts' balances
contract ProtocolBalancesTest is BaseTest {
    StakerGatewayHandler handler;

    // Expose functions from stakergateway handler
    function setUp() public override {
        super.setUp();

        // create handler
        handler = new StakerGatewayHandler(config, tokens.a);
        targetContract(address(handler));

        // select handler's functions to expose
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.stake.selector;
        selectors[1] = handler.stakeNative.selector;
        selectors[2] = handler.unstake.selector;
        selectors[3] = handler.unstakeNative.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    //
    function invariant_Balances() public view {
        // snapshot balances
        BalancesERC20 memory balancesTokenA = _makeERC20BalanceSnapshot(tokens.a);
        BalancesERC20 memory balancesTokenB = _makeERC20BalanceSnapshot(tokens.b);
        BalancesERC20 memory balancesTokenWBNB = _makeERC20BalanceSnapshot(IERC20Demo(address(tokens.wbnb)));
        Balances memory nativeBalances = _makeBalanceSnapshot();
        BalancesVaults memory vaultsBalances = _makeVaultsBalanceSnapshot();

        // assert StakerGateawy balances
        assertEq(balancesTokenA.stakerGateway, 0, "Token A's Balance of StakerGateway should be 0");
        assertEq(balancesTokenB.stakerGateway, 0, "Token B's Balance of StakerGateway should be 0");
        assertEq(balancesTokenWBNB.stakerGateway, 0, "Token WBNB's Balance of StakerGateway should be 0");
        assertEq(nativeBalances.stakerGateway, 0, "ETH Balance of StakerGateway should be 0");

        // assert AssetRegistry balances
        assertEq(balancesTokenA.assetRegistry, 0, "Token A's Balance of AssetRegistry should be 0");
        assertEq(balancesTokenB.assetRegistry, 0, "Token B's Balance of AssetRegistry should be 0");
        assertEq(balancesTokenWBNB.assetRegistry, 0, "Token WBNB's Balance of AssetRegistry should be 0");
        assertEq(nativeBalances.stakerGateway, 0, "ETH Balance of AssetRegistry should be 0");

        // Vault TokenA
        assertEq(
            vaultsBalances.vaultAssetA,
            handler.vaultToBalance(address(tokens.a)),
            "Unexpected balance of Vault managing Token A"
        );

        // Vault TokenB
        assertEq(vaultsBalances.vaultAssetB, 0, "Unexpected balance of Vault managing Token B");

        // Vault TokenWBNB
        assertEq(
            vaultsBalances.vaultAssetWBNB,
            handler.vaultToBalance(address(tokens.wbnb)),
            "Unexpected balance of Vault managing Token WBNB"
        );
    }
}
