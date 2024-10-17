// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { IHasConfigUpgradeable } from "src/interfaces/IHasConfigUpgradeable.sol";

import { BaseTest } from "test/BaseTest.sol";

contract GetConfigTest is BaseTest {
    ///
    function test_AssetRegistry_GetConfig() public view {
        assertEq(IHasConfigUpgradeable(address(assetRegistry)).getConfig(), address(config));
    }
    ///
    ///

    function test_StakerGateway_GetConfig() public view {
        assertEq(IHasConfigUpgradeable(address(stakerGateway)).getConfig(), address(config));
    }
    ///
    ///

    function test_Vault_GetConfig() public view {
        assertEq(IHasConfigUpgradeable(address(_getVault(tokens.a))).getConfig(), address(config));
    }
}
