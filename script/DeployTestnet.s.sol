// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { ERC20Demo } from "test/mock/ERC20Demo.sol";

import { BaseScript } from "script/BaseScript.sol";
import { console } from "forge-std/Script.sol";

contract DeployTestnet is BaseScript {
    // address of BNBX token on BSC testnet
    address constant BNBX_ADDRESS = address(0x6cd3f51A92d022030d6e75760200c051caA7152A);

    // address of WBNB token on BSC testnet
    address constant WBNB_ADDRESS = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

    /**
     *
     */
    function run() external {
        _deploy();
    }

    /// @notice Deploy
    function _deploy() internal {
        DeployOutput memory deployOutput;

        // print users debug
        _printUsersDebug();

        // start broadcast
        _startBroadcastByDeployer();

        // deploy ProxyAdmin
        console.log("##### ProxyAdmin");
        _deployProxyAdmin(deployOutput);

        // deploy config
        console.log("##### Config");
        _deployConfig(deployOutput, WBNB_ADDRESS);

        // temporarily grant roles to deployer
        deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getDeployer().addr);
        deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getDeployer().addr);

        // deploy asset registry
        console.log("##### Asset Registry");
        _deployAssetRegistry(deployOutput);

        // set AssetRegistry address in config
        deployOutput.config.setAddress("ASSET_REGISTRY", address(deployOutput.assetRegistry));

        // deploy staker gateway
        console.log("##### StakerGateway");
        _deployStakerGateway(deployOutput);

        //
        deployOutput.config.setAddress("STAKER_GATEWAY", address(deployOutput.stakerGateway));

        // deploy ERC20 demo tokens
        console.log("##### Vaults and ERC20 tokens");
        _deployERC20DemoToken(deployOutput, "A", 100 ether);
        _deployERC20DemoToken(deployOutput, "B", 100 ether);
        _deployMockWBNB(deployOutput, 100 ether);

        // deploy vaults for existing ERC20 tokens
        _deployVault(deployOutput, ERC20Demo(BNBX_ADDRESS), 100 ether);
        _deployVault(deployOutput, ERC20Demo(WBNB_ADDRESS), 100 ether);

        console.log("");

        // grant definitive roles
        deployOutput.config.grantRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getAdmin().addr);
        deployOutput.config.grantRole(deployOutput.config.ROLE_MANAGER(), _getManager().addr);
        deployOutput.config.grantRole(deployOutput.config.ROLE_PAUSER(), _getPauser().addr);

        deployOutput.config.revokeRole(deployOutput.config.ROLE_MANAGER(), _getDeployer().addr);
        deployOutput.config.revokeRole(deployOutput.config.ROLE_PAUSER(), _getDeployer().addr);
        deployOutput.config.revokeRole(deployOutput.config.DEFAULT_ADMIN_ROLE(), _getDeployer().addr);

        // todo: transfer ownership of ProxyAdmin(s)
        deployOutput.proxyAdmin.transferOwnership(_getAdmin().addr);

        _stopBroadcast();

        // check config
        console.log("");
        console.log("CONFIG CHECK: ", deployOutput.config.check());
    }
}
