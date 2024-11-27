// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { AddressUtils } from "extra/AddressUtils.sol";
import { DeployProtocolAbstract } from "script/DeployProtocolAbstract.s.sol";

contract DeployToBscTestnet is DeployProtocolAbstract {
    // address of BNBX token on BSC testnet
    address constant BNBX_ADDRESS = address(0x6cd3f51A92d022030d6e75760200c051caA7152A);

    // address of slisBNB token on BSC testnet
    address constant SLIS_BNB_ADDRESS = address(0xCc752dC4ae72386986d011c2B485be0DAd98C744);

    // address of WBNB token on BSC testnet
    address constant WBNB_ADDRESS = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

    function run() external {
        // supported ERC20 tokens
        address[] memory erc20Tokens = AddressUtils._buildArray2(BNBX_ADDRESS, SLIS_BNB_ADDRESS);

        // prompt to deploy demo ERC20
        bool deployDemoTokens = vm.parseBool(vm.prompt("Deploy demo tokens? [true/false]"));

        // start broadcast
        _startBroadcast();

        // deploy protocol
        _deployProtocol(WBNB_ADDRESS, _getAdmin(), erc20Tokens, deployDemoTokens);

        // stop broadcast
        _stopBroadcast();
    }
}
