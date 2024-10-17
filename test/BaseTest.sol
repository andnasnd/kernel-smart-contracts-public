// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Test, console } from "forge-std/Test.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { AssetRegistry } from "src/AssetRegistry.sol";
import { KernelConfig } from "src/KernelConfig.sol";
import { KernelVault } from "src/KernelVault.sol";
import { StakerGateway } from "src/StakerGateway.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { WBNB } from "test/mock/WBNB.sol";

abstract contract BaseTest is Test {
    ///
    struct Balances {
        uint256 stakerGateway;
        uint256 assetRegistry;
        uint256 vaultAssetA;
        uint256 vaultAssetB;
        uint256 vaultAssetWBNB;
        uint256 deployer;
        uint256 admin;
        uint256 manager;
        uint256 alice;
        uint256 bob;
    }

    ///
    struct ERC20Tokens {
        ERC20Demo a;
        ERC20Demo b;
        WBNB wbnb;
    }

    ///
    struct Users {
        address payable deployer;
        address payable admin;
        address payable manager;
        address payable pauser;
        address payable alice;
        address payable bob;
    }

    ///
    IKernelConfig internal config;
    IAssetRegistry internal assetRegistry;
    IStakerGateway internal stakerGateway;
    UpgradeableBeacon internal vaultBeacon;
    ProxyAdmin internal proxyAdmin;

    ///
    Users internal users;

    ///
    ERC20Tokens internal tokens;

    // ---------------------------------------------------------------------------------- //

    function setUp() public virtual {
        // create Users
        _createUsers();

        //
        _deployWithVaults();

        // print debug addresses
        // _printDebugAddresses();
    }

    // ---------------------------------------------------------------------------------- //

    /// @dev Generates an address by hashing the name and give some ETH
    function _createUser(string memory name) internal returns (address payable) {
        address payable _address = payable(makeAddr(name));
        vm.deal(_address, 10_000 ether);

        return _address;
    }

    /// @dev Creates users for the tests.
    function _createUsers() private {
        users = Users({
            deployer: _createUser("deployer"),
            admin: _createUser("admin"),
            manager: _createUser("manager"),
            pauser: _createUser("pauser"),
            alice: _createUser("alice"),
            bob: _createUser("bob")
        });
    }

    ///
    function _deploy(bool addVaults) private {
        // deploy ProxyAdmin
        proxyAdmin = _deployProxyAdmin();

        // deploy ERC20 tokens
        tokens = ERC20Tokens({ a: _deployMockERC20("A"), b: _deployMockERC20("B"), wbnb: _deployMockWBNB() });

        // deploy config
        config = _deployConfig(tokens.wbnb);

        // deploy asset registry
        assetRegistry = _deployAssetRegistry(address(config));

        // deploy Vaults
        if (addVaults) {
            // deploy respective vaults
            KernelVault vaultA = _deployVault(tokens.a, address(config), 1000 ether);
            KernelVault vaultB = _deployVault(tokens.b, address(config), 1000 ether);
            KernelVault vaultWBNB = _deployVault(ERC20Demo(address(tokens.wbnb)), address(config), 1000 ether);

            // add assets
            vm.startPrank(users.manager);
            assetRegistry.addAsset(address(vaultA));
            assetRegistry.addAsset(address(vaultB));
            assetRegistry.addAsset(address(vaultWBNB));
            vm.stopPrank();
        }

        // set AssetRegistry address in config
        vm.startPrank(users.admin);
        config.setAddress("ASSET_REGISTRY", address(assetRegistry));
        vm.stopPrank();

        // deploy staker gateway
        stakerGateway = _deployStakerGateway(address(config));

        //
        vm.startPrank(users.admin);
        config.setAddress("STAKER_GATEWAY", address(stakerGateway));
        vm.stopPrank();

        // check config
        assertTrue(config.check());
    }

    /// Deploy AssetRegistry
    function _deployAssetRegistry(address configAddr) private returns (IAssetRegistry) {
        // start prank
        vm.startPrank(users.deployer);

        // deploy
        AssetRegistry implementation = new AssetRegistry();
        TransparentUpgradeableProxy proxy =
            _deployTransparentProxy(address(implementation), abi.encodeCall(IAssetRegistry.initialize, (configAddr)));

        // stop prank
        vm.stopPrank();

        return IAssetRegistry(address(proxy));
    }

    ///
    function _deployBeaconProxy(address beacon, bytes memory initializeData) internal returns (BeaconProxy) {
        return new BeaconProxy(beacon, initializeData);
    }

    /// Deploy AssetRegistrConfig
    function _deployConfig(WBNB wbnb_) internal returns (IKernelConfig) {
        // start prank
        vm.startPrank(users.deployer);

        // deploy
        KernelConfig implementation = new KernelConfig();
        TransparentUpgradeableProxy proxy = _deployTransparentProxy(
            address(implementation), abi.encodeCall(IKernelConfig.initialize, (users.admin, address(wbnb_)))
        );

        IKernelConfig config_ = IKernelConfig(address(proxy));

        vm.stopPrank();

        // grant roles
        vm.startPrank(users.admin);
        config_.grantRole(implementation.DEFAULT_ADMIN_ROLE(), users.admin);
        config_.grantRole(implementation.ROLE_MANAGER(), users.manager);
        config_.grantRole(implementation.ROLE_PAUSER(), users.pauser);

        vm.stopPrank();

        //
        return config_;
    }

    /// Deploy a demo ERC20 token
    function _deployMockERC20(string memory symbol) internal returns (ERC20Demo) {
        // start prank
        vm.startPrank(users.deployer);

        // deploy
        ERC20Demo token = new ERC20Demo(symbol, symbol);

        // if (amountMintedToDeployer > 0) {
        //     token.mint(msg.sender, amountMintedToDeployer);
        // }

        // stop prank
        vm.stopPrank();

        return token;
    }

    /// Deploy a demo WBNB token
    function _deployMockWBNB() internal returns (WBNB) {
        // start prank
        vm.startPrank(users.deployer);

        // deploy
        WBNB token = new WBNB();

        // stop prank
        vm.stopPrank();

        return token;
    }

    ///
    function _deployProxyAdmin() internal returns (ProxyAdmin) {
        return new ProxyAdmin();
    }

    /// Deploy StakerGateway
    function _deployStakerGateway(address configAddr) internal returns (IStakerGateway) {
        // start prank
        vm.startPrank(users.deployer);

        // deploy
        StakerGateway implementation = new StakerGateway();
        TransparentUpgradeableProxy proxy =
            _deployTransparentProxy(address(implementation), abi.encodeCall(IStakerGateway.initialize, (configAddr)));

        // stop prank
        vm.stopPrank();

        return IStakerGateway(address(proxy));
    }

    ///
    function _deployTransparentProxy(
        address implementation,
        bytes memory initializeData
    )
        internal
        returns (TransparentUpgradeableProxy)
    {
        return new TransparentUpgradeableProxy(implementation, address(proxyAdmin), initializeData);
    }

    function _deployVaultBeacon() internal returns (UpgradeableBeacon) {
        // deploy implementation
        KernelVault kernelVaultImplementation = new KernelVault();

        // deploy Beacon
        UpgradeableBeacon vaultBeacon_ = new UpgradeableBeacon(address(kernelVaultImplementation));

        return vaultBeacon_;
    }

    /// Deploy a KernelVault
    function _deployVault(ERC20Demo asset, address configAddr, uint256 depositLimit) internal returns (KernelVault) {
        // deploy vaultBeacon
        if (address(vaultBeacon) == address(0)) {
            vaultBeacon = _deployVaultBeacon();
        }

        // initialize
        bytes memory initializeData = abi.encodeCall(IKernelVault.initialize, (address(asset), configAddr));
        BeaconProxy proxy = _deployBeaconProxy(address(vaultBeacon), initializeData);

        // set deposit limit
        _setDepositLimit(KernelVault(address(proxy)), depositLimit);

        return KernelVault(address(proxy));
    }

    ///
    function _deployWithVaults() internal {
        _deploy(true);
    }

    ///
    function _deployWithoutVaults() internal {
        _deploy(false);
    }

    ///
    function _expectRevertCustomError(bytes4 selector) internal {
        vm.expectRevert(selector);
    }

    ///
    function _expectRevertCustomErrorWithMessage(bytes4 selector, string memory message) internal {
        vm.expectRevert(abi.encodeWithSelector(selector, message));
    }

    ///
    function _expectRevertMessage(string memory message) internal {
        vm.expectRevert(bytes(message));
    }

    ///
    function _getVault(ERC20Demo asset) internal view returns (KernelVault) {
        return KernelVault(assetRegistry.getVault(address(asset)));
    }

    /// Make ERC20 token snapshot
    function _makeBalanceSnapshot() internal view returns (Balances memory) {
        return Balances({
            stakerGateway: address(stakerGateway).balance,
            assetRegistry: address(assetRegistry).balance,
            vaultAssetA: stakerGateway.getVault(address(tokens.a)).balance,
            vaultAssetB: stakerGateway.getVault(address(tokens.b)).balance,
            vaultAssetWBNB: stakerGateway.getVault(address(ERC20Demo(address(tokens.wbnb)))).balance,
            deployer: users.deployer.balance,
            admin: users.admin.balance,
            manager: users.manager.balance,
            alice: users.alice.balance,
            bob: users.bob.balance
        });
    }

    /// Mint ERC20 tokens
    function _makeERC20BalanceSnapshot(ERC20Demo asset) internal view returns (Balances memory) {
        return Balances({
            stakerGateway: asset.balanceOf(address(stakerGateway)),
            assetRegistry: asset.balanceOf(address(assetRegistry)),
            vaultAssetA: asset.balanceOf(stakerGateway.getVault(address(tokens.a))),
            vaultAssetB: asset.balanceOf(stakerGateway.getVault(address(tokens.b))),
            vaultAssetWBNB: asset.balanceOf(stakerGateway.getVault(address(ERC20Demo(address(tokens.wbnb))))),
            deployer: asset.balanceOf(users.deployer),
            admin: asset.balanceOf(users.admin),
            manager: asset.balanceOf(users.manager),
            alice: asset.balanceOf(users.alice),
            bob: asset.balanceOf(users.bob)
        });
    }

    ///
    function _mintERC20(ERC20Demo asset, address to, uint256 amount) internal {
        asset.mint(to, amount);
    }

    /// Stake
    function _mintAndStake(address sender, ERC20Demo asset, uint256 amount) internal {
        vm.startPrank(sender);

        _mintERC20(asset, sender, amount);

        // stake
        _stake(sender, asset, amount);

        //
        vm.stopPrank();
    }

    ///
    function _printDebugAddresses() internal view {
        console.log("");
        console.log("ADDRESSES:");
        console.log("  alice:       ", users.alice);
        console.log("  deployer:    ", users.deployer);
        console.log("  admin:       ", users.admin);
        console.log("  manager:     ", users.manager);
        console.log("  pauser:      ", users.pauser);
        console.log("  alice:       ", users.alice);
        console.log("  bob:         ", users.bob);
        console.log("  proxyAdmin:  ", address(proxyAdmin));
        console.log("  stakerGateway:", address(stakerGateway));
        console.log("  assetRegistry:", address(assetRegistry));

        if (address(tokens.a) != address(0)) {
            console.log("  vaultAssetA:", stakerGateway.getVault(address(tokens.a)));
        }
        if (address(tokens.b) != address(0)) {
            console.log("  vaultAssetB:", stakerGateway.getVault(address(tokens.b)));
        }
        if (address(tokens.wbnb) != address(0)) {
            console.log("  vaultAssetWBNB:", stakerGateway.getVault(address(ERC20Demo(address(tokens.wbnb)))));
        }

        console.log("");
    }

    ///
    function _setDepositLimit(KernelVault vault, uint256 limit) internal {
        vm.startPrank(users.manager);
        vault.setDepositLimit(limit);
        vm.stopPrank();
    }

    /// Stake
    function _stake(address sender, ERC20Demo asset, uint256 amount) internal {
        vm.startPrank(sender);

        // approve ERC20
        asset.approve(address(stakerGateway), amount);

        // stake
        stakerGateway.stake(address(asset), amount, "referral_id");

        //
        vm.stopPrank();
    }

    /// Stake native
    function _stakeNative(address sender, uint256 amount) internal {
        vm.startPrank(sender);
        stakerGateway.stakeNative{ value: amount }("referral_id");
        vm.stopPrank();
    }

    /// Pause vault deposits
    function _pauseVaultsDeposit() internal {
        vm.startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        vm.stopPrank();
    }

    /// Pause vault withdraw
    function _pauseVaultsWithdraw() internal {
        vm.startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_WITHDRAW");
        vm.stopPrank();
    }

    /// Pause protocol
    function _pauseProtocol() internal {
        vm.startPrank(users.pauser);
        config.pauseFunctionality("PROTOCOL");
        vm.stopPrank();
    }
}
