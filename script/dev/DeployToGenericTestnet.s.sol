// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { DeployProtocolAbstract } from "script/DeployProtocolAbstract.s.sol";

contract DeployToGenericTestnet is DeployProtocolAbstract {
    function run() external {
        // deploy mock WBNB token
        _startBroadcast();
        address wbnbAddress = _deployMockWBNB();
        _stopBroadcast();

        // prompt to deploy demo ERC20
        bool deployDemoTokens = vm.parseBool(vm.prompt("Deploy demo tokens? [true/false]"));

        // start broadcast
        _startBroadcast();

        // deploy protocol
        _deployProtocol(wbnbAddress, _getAdmin(), new address[](0), deployDemoTokens);

        // stop broadcast
        _stopBroadcast();
    }
}
