// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Upgrades } from "@openzeppelin/upgrades/Upgrades.sol";

import { AddressUtils } from "extra/AddressUtils.sol";
import { AssetRegistry } from "src/AssetRegistry.sol";
import { KernelConfig } from "src/KernelConfig.sol";
import { KernelVault } from "src/KernelVault.sol";
import { StakerGateway } from "src/StakerGateway.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";

import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { WBNB } from "test/mock/WBNB.sol";
import { Script, console } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    /// Used to keep track of deployed contracts and other info
    struct DeployOutput {
        IAssetRegistry assetRegistry;
        KernelConfig config;
        StakerGateway stakerGateway;
        UpgradeableBeacon vaultUpgradeableBeacon;
    }

    /* Modifiers ********************************************************************************************************/

    ///
    modifier requiresDeployedAssetRegistry(DeployOutput memory deployOutput) {
        require(address(deployOutput.assetRegistry) != address(0), "AssetRegistry not deployed");
        _;
    }

    ///
    modifier requiresDeployedConfig(DeployOutput memory deployOutput) {
        require(address(deployOutput.config) != address(0), "KernelConfig not deployed");
        _;
    }

    ///
    modifier requiresDeployedVaultUpgradeableBeacon(DeployOutput memory deployOutput) {
        require(address(deployOutput.vaultUpgradeableBeacon) != address(0), "KernelVault Beacon not deployed");
        _;
    }

    /* Setup ************************************************************************************************************/

    function setUp() public virtual { }

    /* Broadcast ********************************************************************************************************/

    ///
    function _startBroadcast() internal {
        vm.startBroadcast();
    }

    ///
    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }

    /* Users ************************************************************************************************************/

    ///
    function _getAdmin() internal view returns (address) {
        return vm.envAddress("ADMIN_ADDRESS");
    }

    ///
    function _getDeployer() internal returns (address) {
        (, address msgSender,) = vm.readCallers();

        return msgSender;
    }

    ///
    function _getManager() internal view returns (address) {
        return vm.envAddress("MANAGER_ADDRESS");
    }

    ///
    function _getPauser() internal view returns (address) {
        return vm.envAddress("PAUSER_ADDRESS");
    }

    ///
    function _getUpgrader() internal view returns (address) {
        return vm.envAddress("UPGRADER_ADDRESS");
    }

    /* Deploy ***********************************************************************************************************/

    /// Deploy AssetRegistry
    function _deployAssetRegistry(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
        console.log("");
        console.log("##### Asset Registry");

        // deploy proxy
        ERC1967Proxy proxy = _deployUUPSProxy(
            "AssetRegistry.sol", abi.encodeCall(IAssetRegistry.initialize, (address(deployOutput.config)))
        );

        //
        deployOutput.assetRegistry = IAssetRegistry(address(proxy));
    }

    ///
    function _deployBeaconProxy(address beacon, bytes memory initializeData) internal returns (BeaconProxy) {
        return BeaconProxy(payable(Upgrades.deployBeaconProxy(beacon, initializeData)));
    }

    /// Deploy Config
    function _deployConfig(DeployOutput memory deployOutput, address wbnbAddress) internal {
        console.log("");
        console.log("##### Config");

        // deploy proxy
        ERC1967Proxy proxy = _deployUUPSProxy(
            "KernelConfig.sol", abi.encodeCall(IKernelConfig.initialize, (_getDeployer(), wbnbAddress))
        );

        //
        deployOutput.config = KernelConfig(address(proxy));
    }

    /// Deploy a demo ERC20 token
    function _deployERC20DemoToken(string memory symbol) internal returns (ERC20Demo) {
        return new ERC20Demo(symbol, symbol);
    }

    /// Deploy a demo ERC20 token, deploy the Vault and add it to kernel
    function _deployERC20DemoTokenAndAddVaultTOAssetRegistry(
        DeployOutput memory deployOutput,
        string memory symbol
    )
        internal
        returns (KernelVault)
    {
        // deploy token
        ERC20Demo token = _deployERC20DemoToken(symbol);

        //
        return _onERC20DemoDeploy(deployOutput, token);
    }

    /// Deploy a demo WBNB token
    function _deployMockWBNB() internal returns (address) {
        // deploy token
        WBNB token = new WBNB();

        //
        return address(token);
    }

    /// Deploy StakerGateway
    function _deployStakerGateway(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
        console.log("");
        console.log("##### StakerGateway");

        // deploy proxy
        ERC1967Proxy proxy = _deployUUPSProxy(
            "StakerGateway.sol", abi.encodeCall(IStakerGateway.initialize, (address(deployOutput.config)))
        );

        //
        deployOutput.stakerGateway = StakerGateway(payable(proxy));
    }

    ///
    function _deployUUPSProxy(
        string memory contractName,
        bytes memory initializeData
    )
        internal
        returns (ERC1967Proxy)
    {
        address proxyAddr = Upgrades.deployUUPSProxy(contractName, initializeData);
        ERC1967Proxy proxy = ERC1967Proxy(payable(proxyAddr));

        // log
        console.log("  UUPS proxy:     ", proxyAddr);
        console.log("  implementation: ", _getProxyImplementation(proxy));

        //
        return proxy;
    }

    /// Deploy a Vault
    function _deployKernelVault(
        DeployOutput memory deployOutput,
        IERC20 asset
    )
        internal
        requiresDeployedConfig(deployOutput)
        requiresDeployedAssetRegistry(deployOutput)
        requiresDeployedVaultUpgradeableBeacon(deployOutput)
        returns (KernelVault)
    {
        // initialize
        bytes memory initializeData =
            abi.encodeCall(IKernelVault.initialize, (address(asset), address(deployOutput.config)));
        BeaconProxy proxy = _deployBeaconProxy(address(deployOutput.vaultUpgradeableBeacon), initializeData);

        //
        KernelVault vault = KernelVault(address(proxy));

        //
        console.log("");
        console.log("  Vault (beacon Proxy)");
        console.log(
            "    for token:      ",
            string.concat(Strings.toHexString(address(asset)), " (", ERC20(address(asset)).symbol(), ")")
        );
        console.log("    proxy:          ", address(proxy));
        console.log("    implementation: ", address(deployOutput.vaultUpgradeableBeacon.implementation()));

        return vault;
    }

    /// Deploy a Vault
    function _deployKernelVaultAndAddToAssetRegistry(
        DeployOutput memory deployOutput,
        IERC20 asset
    )
        internal
        requiresDeployedConfig(deployOutput)
        requiresDeployedAssetRegistry(deployOutput)
        returns (KernelVault)
    {
        // deploy Vault
        KernelVault vault = _deployKernelVault(deployOutput, asset);

        // add asset to AssetRegistry
        deployOutput.assetRegistry.addAsset(address(vault));

        // return
        return vault;
    }

    /// Deploy Vault Beacon
    function _deployKernelVaultUpgradeableBeacon(DeployOutput memory deployOutput) internal {
        // deploy Beacon
        address upgradeableBeaconAddress = Upgrades.deployBeacon("KernelVault.sol:KernelVault", _getAdmin());

        // log
        console.log("");
        console.log("  Vault UpgradeableBeacon");
        console.log("    UpgradeableBeacon deployed at:          ", upgradeableBeaconAddress);
        console.log(
            "    KernelVault implementation deployed at: ", UpgradeableBeacon(upgradeableBeaconAddress).implementation()
        );

        //
        deployOutput.vaultUpgradeableBeacon = UpgradeableBeacon(upgradeableBeaconAddress);
    }

    /// @notice Deploy a TimelockController contract
    /// @param proposers array of addresses with PROPOSER_ROLE that can propose scheduled transactions
    function _deployTimelockController(address[] memory proposers, uint256 time) public returns (TimelockController) {
        console.log("");
        console.log(" ##### DEPLOY TIMELOCK");

        // anyone can execute
        address[] memory executors = AddressUtils._buildArray1(address(0));

        // deploy Timelock
        TimelockController timelock = new TimelockController(time, proposers, executors, address(0));

        console.log("  Timelock deployed at: ", address(timelock));

        return timelock;
    }

    ///
    function _getProxyImplementation(ERC1967Proxy proxy) internal view returns (address) {
        return Upgrades.getImplementationAddress(address(proxy));
    }

    /// Deploy a demo WBNB token
    function _onERC20DemoDeploy(DeployOutput memory deployOutput, ERC20Demo token) internal returns (KernelVault) {
        // log
        console.log(string.concat("  Deployed demo ERC20 token \"", token.symbol(), "\" at "), address(token));

        // deploy Vault
        return _deployKernelVaultAndAddToAssetRegistry(deployOutput, token);
    }

    ///
    function _printDebugAddress(string memory name, address addr) internal pure {
        console.log(string.concat("  ", name, ":     ", Strings.toHexString(addr)));
    }

    ///
    function _printUsersDebug() internal {
        console.log("");
        console.log("##### Users");
        _printDebugAddress("Deployer", _getDeployer());
        _printDebugAddress("Admin", _getAdmin());
        _printDebugAddress("Manager", _getManager());
        _printDebugAddress("Pauser", _getPauser());
    }

    ///
    function _promptAddress(string memory input) internal returns (address) {
        return vm.parseAddress(vm.prompt(input));
    }
}
