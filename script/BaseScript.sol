// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

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
        ProxyAdmin proxyAdmin;
        StakerGateway stakerGateway;
        UpgradeableBeacon vaultUpgradeableBeacon;
    }

    ///
    struct Wallet {
        address addr;
        uint256 privateKey;
    }

    /* Modifiers ********************************************************************************************************/

    ///
    modifier requiresDeployedAssetRegistry(DeployOutput memory deployOutput) {
        require(address(deployOutput.assetRegistry) != address(0));
        _;
    }

    ///
    modifier requiresDeployedConfig(DeployOutput memory deployOutput) {
        require(address(deployOutput.config) != address(0));
        _;
    }

    ///
    modifier requiresDeployedProxyAdmin(DeployOutput memory deployOutput) {
        require(address(deployOutput.proxyAdmin) != address(0));
        _;
    }

    /* Setup ************************************************************************************************************/

    function setUp() public virtual { }

    /* Broadcast ********************************************************************************************************/

    ///
    function _startBroadcast(Wallet memory wallet) internal {
        vm.startBroadcast(wallet.privateKey);
    }

    ///
    function _startBroadcastByDeployer() internal {
        _startBroadcast(_getDeployer());
    }

    ///
    function _stopBroadcast() internal {
        vm.stopBroadcast();
    }

    /* Users ************************************************************************************************************/

    ///
    function _createWallet(address addr, uint256 privateKey) internal pure returns (Wallet memory) {
        return Wallet({ addr: addr, privateKey: privateKey });
    }

    ///
    function _getAdmin() internal returns (Wallet memory) {
        return _createWallet(
            vm.createWallet(vm.envUint("ADMIN_PRIVATE_KEY")).addr,
            vm.createWallet(vm.envUint("ADMIN_PRIVATE_KEY")).privateKey
        );
    }

    ///
    function _getDeployer() internal returns (Wallet memory) {
        return _createWallet(
            vm.createWallet(vm.envUint("DEPLOYER_PRIVATE_KEY")).addr,
            vm.createWallet(vm.envUint("DEPLOYER_PRIVATE_KEY")).privateKey
        );
    }

    ///
    function _getManager() internal returns (Wallet memory) {
        return _createWallet(
            vm.createWallet(vm.envUint("MANAGER_PRIVATE_KEY")).addr,
            vm.createWallet(vm.envUint("MANAGER_PRIVATE_KEY")).privateKey
        );
    }

    ///
    function _getPauser() internal returns (Wallet memory) {
        return _createWallet(
            vm.createWallet(vm.envUint("PAUSER_PRIVATE_KEY")).addr,
            vm.createWallet(vm.envUint("PAUSER_PRIVATE_KEY")).privateKey
        );
    }

    /* Deploy ***********************************************************************************************************/

    /// Deploy AssetRegistry
    function _deployAssetRegistry(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
        // deploy implementation
        AssetRegistry implementation = new AssetRegistry();

        // deploy proxy
        TransparentUpgradeableProxy proxy = _deployTransparentProxy(
            deployOutput,
            address(implementation),
            abi.encodeCall(IAssetRegistry.initialize, (address(deployOutput.config)))
        );

        //
        deployOutput.assetRegistry = IAssetRegistry(address(proxy));
    }

    ///
    function _deployBeaconProxy(address beacon, bytes memory initializeData) internal returns (BeaconProxy) {
        return new BeaconProxy(beacon, initializeData);
    }

    /// Deploy Config
    function _deployConfig(DeployOutput memory deployOutput, address wbnbAddress) internal {
        // deploy implementation
        KernelConfig implementation = new KernelConfig();

        // deploy proxy
        TransparentUpgradeableProxy proxy = _deployTransparentProxy(
            deployOutput,
            address(implementation),
            abi.encodeCall(IKernelConfig(address(implementation)).initialize, (_getDeployer().addr, wbnbAddress))
        );

        // log
        console.log(string.concat("  role DEFAULT_ADMIN_ROLE to: ", Strings.toHexString(_getAdmin().addr)));
        console.log(string.concat("  role ROLE_MANAGER to:       ", Strings.toHexString(_getManager().addr)));
        console.log(string.concat("  role ROLE_PAUSER to:        ", Strings.toHexString(_getPauser().addr)));
        console.log("");

        //
        deployOutput.config = KernelConfig(address(proxy));
    }

    /// Deploy a demo ERC20 token
    function _deployERC20DemoToken(
        DeployOutput memory deployOutput,
        string memory symbol,
        uint256 vaultDepositLimit
    )
        internal
        returns (ERC20Demo)
    {
        // deploy token
        ERC20Demo token = new ERC20Demo(symbol, symbol);

        //
        _onERC20DemoDeploy(deployOutput, token, vaultDepositLimit);

        //
        return token;
    }

    /// Deploy a demo WBNB token
    function _deployMockWBNB(DeployOutput memory deployOutput, uint256 vaultDepositLimit) internal returns (WBNB) {
        // deploy token
        WBNB token = new WBNB();

        //
        _onERC20DemoDeploy(deployOutput, ERC20Demo(address(token)), vaultDepositLimit);

        //
        return token;
    }

    ///
    function _deployProxyAdmin(DeployOutput memory deployOutput) internal {
        ProxyAdmin proxyAdmin_ = new ProxyAdmin();

        // log
        console.log("  proxy: ", address(proxyAdmin_));
        console.log("");

        //
        deployOutput.proxyAdmin = proxyAdmin_;
    }

    /// Deploy StakerGateway
    function _deployStakerGateway(DeployOutput memory deployOutput) internal requiresDeployedConfig(deployOutput) {
        // deploy implementation
        StakerGateway implementation = new StakerGateway();

        // deploy proxy
        TransparentUpgradeableProxy proxy = _deployTransparentProxy(
            deployOutput,
            address(implementation),
            abi.encodeCall(IStakerGateway.initialize, (address(deployOutput.config)))
        );

        //
        deployOutput.stakerGateway = StakerGateway(payable(proxy));
    }

    ///
    function _deployTransparentProxy(
        DeployOutput memory deployOutput,
        address implementation,
        bytes memory initializeData
    )
        internal
        requiresDeployedProxyAdmin(deployOutput)
        returns (TransparentUpgradeableProxy)
    {
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(implementation, address(deployOutput.proxyAdmin), initializeData);

        // log
        console.log("  proxy:          ", address(proxy));
        console.log("  implementation: ", implementation);
        console.log("");

        //
        return proxy;
    }

    /// Deploy a Vault
    function _deployVault(
        DeployOutput memory deployOutput,
        ERC20Demo asset,
        uint256 depositLimit
    )
        internal
        requiresDeployedConfig(deployOutput)
        requiresDeployedAssetRegistry(deployOutput)
        returns (KernelVault)
    {
        // deploy vaultUpgradeableBeacon
        if (address(deployOutput.vaultUpgradeableBeacon) == address(0)) {
            deployOutput.vaultUpgradeableBeacon = _deployVaultUpgradeableBeacon();
        }

        // initialize
        bytes memory initializeData =
            abi.encodeCall(IKernelVault.initialize, (address(asset), address(deployOutput.config)));
        BeaconProxy proxy = _deployBeaconProxy(address(deployOutput.vaultUpgradeableBeacon), initializeData);

        //
        KernelVault vault = KernelVault(address(proxy));

        // set deposit limit
        vault.setDepositLimit(depositLimit);

        // add asset to AssetRegistry
        deployOutput.assetRegistry.addAsset(address(vault));

        //
        console.log("  Vault (beacon Proxy)");
        console.log("    for token:      ", address(asset));
        console.log("    proxy:          ", address(proxy));
        console.log("    implementation: ", address(deployOutput.vaultUpgradeableBeacon.implementation()));
        console.log("");

        return vault;
    }

    /// Deploy Vault Beacon
    function _deployVaultUpgradeableBeacon() internal returns (UpgradeableBeacon) {
        KernelVault kernelVaultImplementation = new KernelVault();

        // deploy Beacon
        UpgradeableBeacon vaultUpgradeableBeacon_ = new UpgradeableBeacon(address(kernelVaultImplementation));

        // log
        console.log("  Vault UpgradeableBeacon");
        console.log("    UpgradeableBeacon deployed at: ", address(vaultUpgradeableBeacon_));
        console.log("");

        //
        return vaultUpgradeableBeacon_;
    }

    /// Deploy a demo WBNB token
    function _onERC20DemoDeploy(
        DeployOutput memory deployOutput,
        ERC20Demo token,
        uint256 vaultDepositLimit
    )
        internal
    {
        // log
        console.log(string.concat("  Deployed demo ERC20 token \"", token.symbol(), "\" at "), address(token));
        console.log("");

        // deploy Vault
        _deployVault(deployOutput, token, vaultDepositLimit);
    }

    ///
    function _printUsersDebug() internal {
        console.log("##### Users");
        _printWalletDebug("Deployer", _getDeployer());
        _printWalletDebug("Admin", _getAdmin());
        _printWalletDebug("Manager", _getManager());
        _printWalletDebug("Pauser", _getPauser());
        console.log("");
    }

    ///
    function _printWalletDebug(string memory name, Wallet memory wallet) internal pure {
        console.log(string.concat("  ", name));
        console.log(string.concat("    address:     ", Strings.toHexString(wallet.addr)));
        // console.log(string.concat("    private key: ", Strings.toHexString(wallet.privateKey)));
    }
}
