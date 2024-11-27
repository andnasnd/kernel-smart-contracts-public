// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Upgrades, Options } from "@openzeppelin/upgrades/Upgrades.sol";
import { Safe } from "@safe-smart-account/contracts/Safe.sol";

import { AssetRegistry } from "src/AssetRegistry.sol";
import { KernelConfig } from "src/KernelConfig.sol";
import { KernelVault } from "src/KernelVault.sol";
import { StakerGateway } from "src/StakerGateway.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";

import { WalletUtils } from "extra/WalletUtils.sol";
import { SafeUtils } from "extra/SafeUtils.sol";

import { ERC20Demo } from "test/mock/ERC20Demo.sol";
import { ERC20WithTranferTaxDemo } from "test/mock/ERC20WithTranferTaxDemo.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";
import { ArrayUtils } from "test/test-utils/ArrayUtils.sol";
import { WBNB } from "test/mock/WBNB.sol";

abstract contract BaseTest is Test {
    using ArrayUtils for address[];

    uint256 internal constant DEFAULT_DEPOSIT_LIMIT = 1000 ether;

    // BSC mainnet constants
    address internal constant CLIS_BNB = 0x4b30fcAA7945fE9fDEFD2895aae539ba102Ed6F6;
    address internal constant HELIO_PROVIDE_V2 = 0xa835F890Fcde7679e7F7711aBfd515d2A267Ed0B;

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
    struct IERC20Tokens {
        IERC20Demo a;
        IERC20Demo b;
        WBNB wbnb;
    }

    ///
    struct Users {
        address payable deployer;
        address payable admin;
        address payable manager;
        address payable pauser;
        address payable upgrader;
        address payable alice;
        address payable bob;
    }

    ///
    KernelConfig internal config;
    IAssetRegistry internal assetRegistry;
    IStakerGateway internal stakerGateway;
    UpgradeableBeacon internal vaultBeacon;

    ///
    Users internal users;

    Vm.Wallet[] internal multisigOwners;

    ///
    IERC20Tokens internal tokens;

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

    /// @notice applies a prank before executing the function and eventually restores the previous caller
    modifier prankAndRestorePrank(address msgSender) {
        (address previousMsgSender, address previousTxOrigin) = _getCurrentCallers();

        // if new pranker is the same as the current caller, do nothing
        bool isNewPrankerDifferent = previousMsgSender != msgSender;

        // start prank
        if (isNewPrankerDifferent) {
            _startPrank(msgSender);
        }

        // execute function
        _;

        // restore prank
        if (isNewPrankerDifferent) {
            vm.stopPrank();

            _startPrank(previousMsgSender);
        }
    }

    // ---------------------------------------------------------------------------------- //

    ///
    function _addAsset(address vaultAddress) private {
        vm.prank(users.admin);
        assetRegistry.addAsset(vaultAddress);
    }

    ///
    function _assertAddressArrayEq(address[] memory a, address[] memory b) internal pure {
        assertEq(a.length, b.length, "Arrays do not have the same size");

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(
                a[i],
                b[i],
                string.concat(
                    "Values at index",
                    Strings.toString(i),
                    " are not equals, ",
                    Strings.toHexString(a[i]),
                    " != ",
                    Strings.toHexString(b[i])
                )
            );
        }
    }

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
            upgrader: _createUser("upgrader"),
            alice: _createUser("alice"),
            bob: _createUser("bob")
        });

        multisigOwners = WalletUtils._buildArray4(
            vm.createWallet("safe_owner_1"),
            vm.createWallet("safe_owner_2"),
            vm.createWallet("safe_owner_3"),
            vm.createWallet("safe_owner_4")
        );
    }

    ///
    function _deploy(bool addVaults) private {
        // deploy ERC20 tokens
        tokens = IERC20Tokens({ a: _deployMockERC20("A"), b: _deployMockERC20("B"), wbnb: _deployMockWBNB() });

        // deploy config
        config = _deployConfig(tokens.wbnb);

        // deploy asset registry
        assetRegistry = _deployAssetRegistry(address(config));

        // deploy Vaults
        if (addVaults) {
            // deploy respective vaults
            _deployKernelVaultAndAddAsset(tokens.a, DEFAULT_DEPOSIT_LIMIT);
            _deployKernelVaultAndAddAsset(tokens.b, DEFAULT_DEPOSIT_LIMIT);
            _deployKernelVaultAndAddAsset(IERC20Demo(address(tokens.wbnb)), DEFAULT_DEPOSIT_LIMIT);
        }

        // set AssetRegistry address in config
        _setAddress("ASSET_REGISTRY", address(assetRegistry));

        // deploy staker gateway
        stakerGateway = _deployStakerGateway(address(config));

        //
        _setAddress("STAKER_GATEWAY", address(stakerGateway));

        // check config
        assertTrue(config.check());
    }

    /// Deploy AssetRegistry
    function _deployAssetRegistry(address configAddr)
        internal
        prankAndRestorePrank(users.deployer)
        returns (IAssetRegistry)
    {
        // deploy
        ERC1967Proxy proxy =
            _deployUUPSProxy("AssetRegistry.sol", abi.encodeCall(IAssetRegistry.initialize, (configAddr)));

        // return
        return IAssetRegistry(address(proxy));
    }

    ///
    function _deployBeaconProxy(address beacon, bytes memory initializeData) internal returns (BeaconProxy) {
        return new BeaconProxy(beacon, initializeData);
    }

    /// Deploy AssetRegistrConfig
    function _deployConfig(WBNB wbnb_) internal returns (KernelConfig) {
        // start prank
        _startPrank(users.deployer);

        // deploy
        ERC1967Proxy proxy = _deployUUPSProxy(
            "KernelConfig.sol", abi.encodeCall(IKernelConfig.initialize, (users.admin, address(wbnb_)))
        );

        vm.stopPrank();

        //
        KernelConfig config_ = KernelConfig(address(proxy));

        // grant roles
        _grantRole(config_, keccak256("MANAGER"), users.manager);
        _grantRole(config_, keccak256("PAUSER"), users.pauser);
        _grantRole(config_, keccak256("UPGRADER"), users.upgrader);

        // return proxy;
        return config_;
    }

    /// Deploy a demo ERC20 token
    function _deployMockERC20(string memory symbol) internal returns (IERC20Demo) {
        // start prank
        _startPrank(users.deployer);

        // deploy
        ERC20Demo token = new ERC20Demo(symbol, symbol);

        // return
        vm.stopPrank();
        return IERC20Demo(address(token));
    }

    /// Deploy a demo ERC20WithTranferTaxDemo token
    /// @param tax value of tax percentage in bps (1000 = 10%)
    function _deployMockERC20WithTranferTaxDemo(
        string memory symbol,
        uint256 tax
    )
        internal
        returns (ERC20WithTranferTaxDemo)
    {
        // start prank
        _startPrank(users.deployer);

        // deploy
        ERC20WithTranferTaxDemo token = new ERC20WithTranferTaxDemo(symbol, symbol, tax);

        // return
        vm.stopPrank();
        return token;
    }

    /// Deploy a demo WBNB token
    function _deployMockWBNB() internal returns (WBNB) {
        // start prank
        _startPrank(users.deployer);

        // deploy
        WBNB token = new WBNB();

        // return
        vm.stopPrank();
        return token;
    }

    /// Deploy StakerGateway
    function _deployStakerGateway(address configAddr) internal returns (IStakerGateway) {
        // start prank
        _startPrank(users.deployer);

        // deploy
        // StakerGateway implementation = new StakerGateway();
        ERC1967Proxy proxy =
            _deployUUPSProxy("StakerGateway.sol", abi.encodeCall(IStakerGateway.initialize, (configAddr)));

        // return
        vm.stopPrank();
        return IStakerGateway(address(proxy));
    }

    ///
    function _deployUUPSProxy(
        string memory contractName,
        bytes memory initializeData
    )
        internal
        returns (ERC1967Proxy)
    {
        address addr = Upgrades.deployUUPSProxy(contractName, initializeData);

        return ERC1967Proxy(payable(addr));
    }

    function _deployKernelVaultBeacon() internal returns (UpgradeableBeacon) {
        // deploy implementation
        KernelVault kernelVaultImplementation = new KernelVault();

        // deploy Beacon
        UpgradeableBeacon vaultBeacon_ = new UpgradeableBeacon(address(kernelVaultImplementation), users.admin);

        return vaultBeacon_;
    }

    /// Deploy a KernelVault
    function _deployKernelVault(IERC20Demo asset, uint256 depositLimit) internal returns (KernelVault) {
        // deploy vaultBeacon
        if (address(vaultBeacon) == address(0)) {
            vaultBeacon = _deployKernelVaultBeacon();
        }

        // initialize
        bytes memory initializeData = abi.encodeCall(IKernelVault.initialize, (address(asset), address(config)));
        BeaconProxy proxy = _deployBeaconProxy(address(vaultBeacon), initializeData);

        // set deposit limit
        _setDepositLimit(KernelVault(address(proxy)), depositLimit);

        // return
        return KernelVault(address(proxy));
    }

    /// Deploy a KernelVault and add the Asset to Asset
    function _deployKernelVaultAndAddAsset(IERC20Demo asset, uint256 depositLimit) internal returns (KernelVault) {
        // deploy Vault
        KernelVault vault = _deployKernelVault(asset, depositLimit);

        // add Asset
        _addAsset(address(vault));

        // return
        return vault;
    }

    /// @notice Deploy
    function _deploySafe() internal prankAndRestorePrank(multisigOwners[0].addr) returns (Safe) {
        return SafeUtils.deploySafe(multisigOwners);
    }

    /// @notice Deploy
    function _deploySafeWithRole(bytes32 role) internal prankAndRestorePrank(multisigOwners[0].addr) returns (Safe) {
        Safe safe = _deploySafe();

        _grantRole(config, role, address(safe));

        return safe;
    }

    ///
    function _deployTimelockController(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    )
        internal
        prankAndRestorePrank(users.deployer)
        returns (TimelockController)
    {
        TimelockController timelockController = new TimelockController(minDelay, proposers, executors, admin);

        return timelockController;
    }

    /// @notice Deploy a Timelock with:
    ///     - 1h minimum delay
    ///     - renounced admin
    ///     - open executors (can be anyone)
    function _deployTimelockControllerWithProposers(address[] memory proposers)
        internal
        prankAndRestorePrank(users.deployer)
        returns (TimelockController)
    {
        address[] memory executors = ArrayUtils.buildAddressArray().add(address(0));
        return _deployTimelockController(3600, proposers, executors, address(0));
    }

    ///
    function _deployWithVaults() internal {
        _deploy(true);
    }

    ///
    function _deployWithoutVaults() internal {
        _deploy(false);
    }

    /// @notice executes a transaction passing through a proposal and having single owners approving it
    function _executeTransactionThroughProposalAndSingleApprovals(
        Safe safe,
        Vm.Wallet[] memory owners,
        address to,
        bytes memory data
    )
        internal
    {
        require(owners.length > 0, "Owners must be at least 1");

        // propose transaction
        _startPrank(owners[0].addr);
        bytes32 safeTxHash = SafeUtils.proposeTransaction(safe, to, data);

        // sign transaction by all other owners
        for (uint256 i = 1; i < owners.length; i++) {
            _startPrank(owners[i].addr);
            SafeUtils.approveTransactionHash(safe, safeTxHash);
        }

        // execute approved transaction
        SafeUtils.executeApprovedTransaction(safe, to, data);
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
    function _expectRevertWithDepositLimitExceeded(uint256 depositAmount, uint256 depositLimit) internal {
        vm.expectRevert(abi.encodeWithSelector(IKernelVault.DepositLimitExceeded.selector, depositAmount, depositLimit));
    }

    ///
    function _expectRevertWithUnauthorizedCaller(address caller) internal {
        vm.expectRevert(abi.encodeWithSelector(IKernelVault.UnauthorizedCaller.selector, caller));
    }

    ///
    function _expectRevertWithUnauthorizedRole(address user, bytes32 role) internal {
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, role));
    }

    ///
    function _expectRevertWithVaultNotFound(address asset) internal {
        vm.expectRevert(abi.encodeWithSelector(IAssetRegistry.VaultNotFound.selector, asset));
    }

    ///
    function _forkBscMainnet() internal {
        vm.createSelectFork("https://bsc-dataseed1.binance.org/");
    }

    ///
    function _getCurrentMsgSender() internal returns (address) {
        (address msgSender,) = _getCurrentCallers();

        return msgSender;
    }

    ///
    function _getCurrentCallers() internal returns (address msgSender, address txOrigin) {
        (, msgSender, txOrigin) = vm.readCallers();
    }

    ///
    function _getProxyImplementation(ERC1967Proxy proxy) internal view returns (address) {
        return Upgrades.getImplementationAddress(address(proxy));
    }

    ///
    function _getVault(IERC20Demo asset) internal view returns (KernelVault) {
        return KernelVault(assetRegistry.getVault(address(asset)));
    }

    ///
    function _grantRole(KernelConfig config_, bytes32 role, address to) internal prankAndRestorePrank(users.admin) {
        config_.grantRole(role, to);
    }

    /// Make ERC20 token snapshot
    function _makeBalanceSnapshot() internal view returns (Balances memory) {
        return Balances({
            stakerGateway: address(stakerGateway).balance,
            assetRegistry: address(assetRegistry).balance,
            vaultAssetA: stakerGateway.getVault(address(tokens.a)).balance,
            vaultAssetB: stakerGateway.getVault(address(tokens.b)).balance,
            vaultAssetWBNB: stakerGateway.getVault(address(IERC20Demo(address(tokens.wbnb)))).balance,
            deployer: users.deployer.balance,
            admin: users.admin.balance,
            manager: users.manager.balance,
            alice: users.alice.balance,
            bob: users.bob.balance
        });
    }

    /// Mint ERC20 tokens
    function _makeERC20BalanceSnapshot(IERC20Demo asset) internal view returns (Balances memory) {
        return Balances({
            stakerGateway: asset.balanceOf(address(stakerGateway)),
            assetRegistry: asset.balanceOf(address(assetRegistry)),
            vaultAssetA: asset.balanceOf(stakerGateway.getVault(address(tokens.a))),
            vaultAssetB: asset.balanceOf(stakerGateway.getVault(address(tokens.b))),
            vaultAssetWBNB: asset.balanceOf(stakerGateway.getVault(address(IERC20Demo(address(tokens.wbnb))))),
            deployer: asset.balanceOf(users.deployer),
            admin: asset.balanceOf(users.admin),
            manager: asset.balanceOf(users.manager),
            alice: asset.balanceOf(users.alice),
            bob: asset.balanceOf(users.bob)
        });
    }

    ///
    function _mintERC20(IERC20Demo asset, address to, uint256 amount) internal {
        asset.mint(to, amount);
    }

    /// Stake
    function _mintAndStake(address sender, IERC20Demo asset, uint256 amount) internal {
        _startPrank(sender);

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
        console.log("  alice:            ", users.alice);
        console.log("  deployer:         ", users.deployer);
        console.log("  admin:            ", users.admin);
        console.log("  manager:          ", users.manager);
        console.log("  pauser:           ", users.pauser);
        console.log("  alice:            ", users.alice);
        console.log("  bob:              ", users.bob);
        console.log("  Multisig owner 0: ", multisigOwners[0].addr);
        console.log("  Multisig owner 1: ", multisigOwners[1].addr);
        console.log("  Multisig owner 2: ", multisigOwners[2].addr);
        console.log("  stakerGateway:    ", address(stakerGateway));
        console.log("  assetRegistry:    ", address(assetRegistry));

        if (address(tokens.a) != address(0)) {
            console.log("  token A:          ", address(tokens.a));
            console.log("  vault token A:    ", stakerGateway.getVault(address(tokens.a)));
        }
        if (address(tokens.b) != address(0)) {
            console.log("  token B:          ", address(tokens.b));
            console.log("  vault token B:    ", stakerGateway.getVault(address(tokens.b)));
        }
        if (address(tokens.wbnb) != address(0)) {
            console.log("  token WBNB:       ", address(tokens.wbnb));
            console.log("  vault token WBNB: ", stakerGateway.getVault(address(tokens.wbnb)));
        }

        console.log("");
    }

    ///
    function _setDepositLimit(KernelVault vault, uint256 limit) internal prankAndRestorePrank(users.manager) {
        vault.setDepositLimit(limit);
    }

    /// Stake
    function _stake(address sender, IERC20Demo asset, uint256 amount) internal {
        _startPrank(sender);

        // approve ERC20
        asset.approve(address(stakerGateway), amount);

        // stake
        stakerGateway.stake(address(asset), amount, "referral_id");

        //
        vm.stopPrank();
    }

    /// Stake native
    function _stakeNative(address sender, uint256 amount) internal {
        _startPrank(sender);
        stakerGateway.stakeNative{ value: amount }("referral_id");
        vm.stopPrank();
    }

    /// Stake native
    function _stakeClisBNB(address sender, uint256 amount) internal {
        _startPrank(sender);
        stakerGateway.stakeClisBNB{ value: amount }("referral_id");
        vm.stopPrank();
    }

    /// Pause vault deposits
    function _pauseVaultsDeposit() internal {
        _startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_DEPOSIT");
        vm.stopPrank();
    }

    /// Pause vault withdraw
    function _pauseVaultsWithdraw() internal {
        _startPrank(users.pauser);
        config.pauseFunctionality("VAULTS_WITHDRAW");
        vm.stopPrank();
    }

    /// Pause protocol
    function _pauseProtocol() internal {
        _startPrank(users.pauser);
        config.pauseFunctionality("PROTOCOL");
        vm.stopPrank();
    }

    ///
    function _startPrank(address msgSender) internal {
        (address previousMsgSender,) = _getCurrentCallers();

        if (previousMsgSender != msgSender) {
            vm.startPrank(msgSender, msgSender);
        }
    }

    /// set AssetRegistry address in config
    function _setAddress(string memory key, address addr) internal {
        _startPrank(users.admin);
        config.setAddress(key, addr);
        vm.stopPrank();
    }

    /// @notice Update a proxy
    /// @param proxyAddr the address of the proxy to upgrade the implementation to
    /// @param contractName the name of the new contract
    /// @param referenceContract the name of the contract that the new one is upgrading
    function _upgradeProxy(address proxyAddr, string memory contractName, string memory referenceContract) internal {
        Options memory opts;
        opts.referenceContract = referenceContract;

        _startPrank(users.upgrader);
        Upgrades.upgradeProxy(proxyAddr, contractName, "", opts);
        vm.stopPrank();
    }
}
