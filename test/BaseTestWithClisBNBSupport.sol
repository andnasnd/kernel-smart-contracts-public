// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { KernelVault } from "src/KernelVault.sol";

import { BaseTest } from "test/BaseTest.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

abstract contract BaseTestWithClisBNBSupport is BaseTest {
    KernelVault internal clisBNBVault;

    ///
    function setUp() public virtual override {
        // setup forking mainnet
        // TODO: consider always forking mainnet
        _forkBscMainnet();
        super.setUp();

        //
        _setAddress("CLIS_BNB_CONTRACT", 0x4b30fcAA7945fE9fDEFD2895aae539ba102Ed6F6);
        _setAddress("HELIO_PROVIDER_CONTRACT", 0xa835F890Fcde7679e7F7711aBfd515d2A267Ed0B);

        // deploy clisBNB Vault
        clisBNBVault = _deployKernelVaultAndAddAsset(IERC20Demo(CLIS_BNB), DEFAULT_DEPOSIT_LIMIT);
    }
}
