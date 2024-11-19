// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { DeployToTestnetAbstract } from "script/dev/DeployToTestnetAbstract.sol";

import { WBNB } from "test/mock/WBNB.sol";

contract DeployToGenericTestnet is DeployToTestnetAbstract {
    function run() external {
        // deploy mock WBNB token
        _startBroadcast();
        WBNB wbnb = new WBNB();
        _stopBroadcast();

        // deploy protocol
        _deploy(address(wbnb), new address[](0));
    }
}
