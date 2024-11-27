// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

contract DeployKernelConfig is BaseScript {
    // address of WBNB token on BSC mainnet
    address constant WBNB_ADDRESS = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    /**
     *
     */
    function run() external {
        _deploy();
    }

    /// @notice Deploy
    function _deploy() internal {
        // start broadcast
        _startBroadcast();

        //
        DeployOutput memory deployOutput;

        // print users debug
        _printUsersDebug();

        // deploy KernelConfig
        _deployConfig(deployOutput, WBNB_ADDRESS);

        // grant definitive roles
        deployOutput.config.grantRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getAdmin());
        deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getManager());
        deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getPauser());

        deployOutput.config.revokeRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getDeployer());

        _stopBroadcast();
    }
}
