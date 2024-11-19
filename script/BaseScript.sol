// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Upgrades } from "@openzeppelin/upgrades/Upgrades.sol";

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

    /* Deploy ***********************************************************************************************************/

    /// Deploy AssetRegistry
    function _deployAssetRegistry(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
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
        // deploy proxy
        ERC1967Proxy proxy = _deployUUPSProxy(
            "KernelConfig.sol", abi.encodeCall(IKernelConfig.initialize, (_getDeployer(), wbnbAddress))
        );

        // log
        console.log(string.concat("  role DEFAULT_ADMIN_ROLE to: ", Strings.toHexString(_getAdmin())));
        console.log(string.concat("  role ROLE_MANAGER to:       ", Strings.toHexString(_getManager())));
        console.log(string.concat("  role ROLE_PAUSER to:        ", Strings.toHexString(_getPauser())));
        console.log("");

        //
        deployOutput.config = KernelConfig(address(proxy));
    }

    /// Deploy a demo ERC20 token
    function _deployERC20DemoToken(
        DeployOutput memory deployOutput,
        string memory symbol
    )
        internal
        returns (KernelVault)
    {
        // deploy token
        ERC20Demo token = new ERC20Demo(symbol, symbol);

        //
        return _onERC20DemoDeploy(deployOutput, token);
    }

    /// Deploy a demo WBNB token
    function _deployMockWBNB(DeployOutput memory deployOutput) internal returns (KernelVault) {
        // deploy token
        WBNB token = new WBNB();

        //
        return _onERC20DemoDeploy(deployOutput, ERC20Demo(address(token)));
    }

    /// Deploy StakerGateway
    function _deployStakerGateway(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
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
        console.log("");

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
        console.log("  Vault (beacon Proxy)");
        console.log(
            "    for token:      ",
            string.concat(Strings.toHexString(address(asset)), " (", ERC20(address(asset)).symbol(), ")")
        );
        console.log("    proxy:          ", address(proxy));
        console.log("    implementation: ", address(deployOutput.vaultUpgradeableBeacon.implementation()));
        console.log("");

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
        console.log("  Vault UpgradeableBeacon");
        console.log("    UpgradeableBeacon deployed at:          ", upgradeableBeaconAddress);
        console.log(
            "    KernelVault implementation deployed at: ", UpgradeableBeacon(upgradeableBeaconAddress).implementation()
        );
        console.log("");

        //
        deployOutput.vaultUpgradeableBeacon = UpgradeableBeacon(upgradeableBeaconAddress);
    }

    ///
    function _getProxyImplementation(ERC1967Proxy proxy) internal view returns (address) {
        return Upgrades.getImplementationAddress(address(proxy));
    }

    /// Deploy a demo WBNB token
    function _onERC20DemoDeploy(DeployOutput memory deployOutput, ERC20Demo token) internal returns (KernelVault) {
        // log
        console.log(string.concat("  Deployed demo ERC20 token \"", token.symbol(), "\" at "), address(token));
        console.log("");

        // deploy Vault
        return _deployKernelVaultAndAddToAssetRegistry(deployOutput, token);
    }

    ///
    function _printDebugAddress(string memory name, address addr) internal pure {
        console.log(string.concat("  ", name, ":     ", Strings.toHexString(addr)));
    }

    ///
    function _printUsersDebug() internal {
        console.log("##### Users");
        _printDebugAddress("Deployer", _getDeployer());
        _printDebugAddress("Admin", _getAdmin());
        _printDebugAddress("Manager", _getManager());
        _printDebugAddress("Pauser", _getPauser());
        console.log("");
    }

    ///
    function _promptAddress(string memory input) internal returns (address) {
        return vm.parseAddress(vm.prompt(input));
    }
}
