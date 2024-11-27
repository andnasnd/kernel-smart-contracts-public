// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";

import { AddressUtils } from "extra/AddressUtils.sol";
import { DeployProtocolAbstract } from "script/DeployProtocolAbstract.s.sol";

import { console } from "forge-std/Script.sol";

import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { KernelConfigUpgraded } from "test/mock/upgradeability/KernelConfigUpgraded.sol";

contract DeployToBscMainnet is DeployProtocolAbstract {
    // address of BNBx token on BSC mainnet
    address constant BNBX_ADDRESS = 0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275;

    // address of BTCB token on BSC mainnet
    address constant BTCB_ADDRESS = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    // address of slisBNB token on BSC mainnet
    address constant SLIS_BNB_ADDRESS = 0xB0b84D294e0C75A6abe60171b70edEb2EFd14A1B;

    // address of SolvBTC token on BSC mainnet
    address constant SOLV_BTC_ADDRESS = 0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7;

    // address of SolvBTC.BBN token on BSC mainnet
    address constant SOLV_BTC_BBN_ADDRESS = 0x1346b618dC92810EC74163e4c27004c921D446a5;

    // address of WBNB token on BSC mainnet
    address constant WBNB_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    TimelockController upgraderTimelock;

    function run() external {
        // external parameters
        address upgraderTimelockProposer = _promptAddress(
            "Address with ROLE_PROPOSER (likely a Safe account) that can propose scheduled transactions to the Upgrader Timelock: "
        );

        // start broadcast
        _startBroadcast();

        // deploy Upgrader Timelock (30 min delay)
        upgraderTimelock = _deployTimelockController(AddressUtils._buildArray1(upgraderTimelockProposer), 30 * 60);

        // list of supported ERC20 tokens
        address[] memory erc20Tokens = new address[](5);

        erc20Tokens[0] = BNBX_ADDRESS;
        erc20Tokens[1] = BTCB_ADDRESS;
        erc20Tokens[2] = SLIS_BNB_ADDRESS;
        erc20Tokens[3] = SOLV_BTC_ADDRESS;
        erc20Tokens[4] = SOLV_BTC_BBN_ADDRESS;

        // deploy Kernel
        // @dev set Timelock Controller as KernelVault Beacon admin
        _deployProtocol(WBNB_ADDRESS, address(upgraderTimelock), erc20Tokens, false);

        // stop broadcast
        _stopBroadcast();
    }

    ///
    function _grantDefinitiveRoles(DeployOutput memory deployOutput) internal override {
        //
        deployOutput.config.grantRole(deployOutput.config.ROLE_UPGRADER(), address(upgraderTimelock));

        // grant definitive roles
        super._grantDefinitiveRoles(deployOutput);
    }
}
