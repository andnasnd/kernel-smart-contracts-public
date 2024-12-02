// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IHasVersion } from "src/interfaces/IHasVersion.sol";
import { IHelioProvider } from "src/interfaces/IHelioProvider.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IWBNB } from "src/interfaces/IWBNB.sol";
import { StakerGatewayStorage } from "src/StakerGatewayStorage.sol";

/**
 * @title StakerGateway
 * @notice Main entry point of the protocol for staking and unstaking
 */
contract StakerGateway is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    HasConfigUpgradeable,
    IStakerGateway,
    IHasVersion,
    StakerGatewayStorage
{
    /* Modifiers ********************************************************************************************************/

    /**
     * @notice Ensures staking handles an amount > 0
     */
    modifier amountNotZero(uint256 amount) {
        require(amount > 0, InvalidArgument("Invalid zero amount"));
        _;
    }

    /**
     * @notice Implements protection against transferring directly BNB to this contract, which is allowed only from
     * Vault managing WBNB
     */
    modifier enableNativeTokenReceive() {
        // enable receive native tokens
        canReceiveNativeTokens = RECEIVE_NATIVE_TOKENS_TRUE;

        // perform operation
        _;

        // restore initial status
        canReceiveNativeTokens = RECEIVE_NATIVE_TOKENS_FALSE;
    }

    /// @notice Reverts if user does not have UPGRADER role
    modifier onlyUpgrader() {
        _config().requireRoleUpgrader(msg.sender);
        _;
    }

    /* Constructor ******************************************************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External Functions ***********************************************************************************************/

    /**
     * @notice Initialize function
     */
    function initialize(address configAddr) external initializer {
        HasConfigUpgradeable.__HasConfig_init(configAddr);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();
    }

    /**
     * @notice Returns the balance of an asset for a given owner
     */
    function balanceOf(address asset, address owner) external view returns (uint256) {
        return _getVaultForAssetAddress(asset).balanceOf(owner);
    }

    /**
     * @notice Returns the address of the Vault for an asset
     */
    function getVault(address asset) external view returns (address) {
        return _getVaultAddressForAssetAddress(asset);
    }

    /**
     * @notice Stakes an ERC20 asset in the protocol
     * @param asset address of the ERC20 token to stake
     * @param amount amount to stake
     * @dev Staker must provide prior approval to this contract for transfering ERC20 asset
     */
    function stake(
        address asset,
        uint256 amount,
        string calldata referralId
    )
        external
        amountNotZero(amount)
        nonReentrant
    {
        _stake(asset, msg.sender, amount, referralId);
    }

    /**
     * @notice Stakes native tokens in the protocol for clisBNB
     * @dev Receives $BNB from msg.sender and delegate $clisBNB to the Vault
     * @dev $clisBNB is a non-transferable token
     * @dev User's staked balance can be read using stakerGateway's balanceOf()
     */
    function stakeClisBNB(string calldata referralId) external payable amountNotZero(msg.value) nonReentrant {
        address assetAddress = _config().getClisBnbAddress();

        // get Vault balance before depositing tokens
        IKernelVault vault = _getVaultForAssetAddress(assetAddress);
        uint256 vaultBalance = vault.balanceERC20();

        // supply $BNB into ListaDao and delegate the received $clisBNB to the Vault
        address helioProvider = _config().getHelioProviderAddress();
        uint256 clisBNBAmount = IHelioProvider(helioProvider).provide{ value: msg.value }(address(vault));

        // stake
        vault.deposit(vaultBalance, msg.sender);

        // emit event
        emit AssetStaked(msg.sender, assetAddress, clisBNBAmount, referralId);
    }

    /**
     * @notice Stakes native tokens in the protocol
     * @dev Internally converts $BNB into $WBNB and deposits them to the Vault
     * @dev verify WNATIVE has same transferFrom() implementation as WBNB before deploying on other chains
     */
    function stakeNative(string calldata referralId) external payable amountNotZero(msg.value) nonReentrant {
        // convert BNB into WBNB (address(this) will be the owner)
        address asset = _config().getWBNBAddress();
        uint256 amount = msg.value;

        IWBNB(asset).deposit{ value: amount }();

        // stake
        _stake(asset, address(this), amount, referralId);
    }

    /**
     * @notice Unstakes an ERC20 asset in the protocol
     * @param asset address of the ERC20 token to unstake
     * @param amount amount to unstake
     */
    function unstake(
        address asset,
        uint256 amount,
        string calldata referralId
    )
        external
        amountNotZero(amount)
        nonReentrant
    {
        _unstake(IERC20(address(asset)), amount, msg.sender, msg.sender, referralId);
    }

    /**
     * @notice Unstakes $clisBNB from the protocol
     * @dev Internally converts $clisBNB back to $BNB and sends them to user
     */
    function unstakeClisBNB(
        uint256 amount,
        string calldata referralId
    )
        external
        amountNotZero(amount)
        nonReentrant
        enableNativeTokenReceive
    {
        address assetAddress = _config().getClisBnbAddress();
        IKernelVault vault = _getVaultForAssetAddress(assetAddress);

        // withdraw from vault
        vault.withdraw(amount, msg.sender, false);

        address helioProvider = _config().getHelioProviderAddress();
        uint256 bnbAmount = IHelioProvider(helioProvider).release(msg.sender, amount);

        // emit event
        emit AssetUnstaked(msg.sender, assetAddress, bnbAmount, referralId);
    }

    /**
     * @notice Unstakes native tokens from the protocol
     * @dev Internally converts $WBNB back to $BNB and sends them to user
     */
    function unstakeNative(
        uint256 amount,
        string calldata referralId
    )
        external
        amountNotZero(amount)
        nonReentrant
        enableNativeTokenReceive
    {
        IWBNB asset = IWBNB(_config().getWBNBAddress());

        // withdraw from vault
        _unstake(IERC20(address(asset)), amount, msg.sender, address(this), referralId);

        // convert $WBNB into $BNB
        asset.withdraw(amount);

        // send $BNB to owner
        (bool sent,) = msg.sender.call{ value: amount }("");
        require(sent, UnstakeFailed("Failed to send tokens to owner"));
    }

    /**
     * @notice return version
     */
    function version() public pure virtual returns (string memory) {
        return "1.0";
    }

    /**
     * @notice Enables receiving native tokens
     * @dev This is necessary to withdraw $WBNB from the Vault and transfer them to the StakerGateway (and then to the
     * user) because WBNB.withdraw() doesn't let specify msg.sender as receiver.
     */
    receive() external payable {
        require(canReceiveNativeTokens == RECEIVE_NATIVE_TOKENS_TRUE, CannotReceiveNativeTokens());
    }

    /* Internal Functions ***********************************************************************************************/

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyUpgrader { }

    /* Private Functions ************************************************************************************************/

    /**
     * @notice Returns the address of the Vault for an asset
     */
    function _getVaultAddressForAssetAddress(address asset) private view returns (address) {
        return IAssetRegistry(_config().getAssetRegistry()).getVault(asset);
    }

    /**
     * @notice Returns the instance of the Vault for an asset
     */
    function _getVaultForAssetAddress(address asset) private view returns (IKernelVault) {
        return IKernelVault(_getVaultAddressForAssetAddress(asset));
    }

    /**
     * @notice Internal function for staking
     */
    function _stake(address asset, address source, uint256 amount, string calldata referralId) private {
        IERC20 asset_ = IERC20(asset);

        // get Vault balance before depositing tokens
        IKernelVault vault = _getVaultForAssetAddress(asset);
        uint256 vaultBalance = vault.balanceERC20();

        // transfer tokens to Vault
        SafeERC20.safeTransferFrom(asset_, source, address(vault), amount);

        // register deposit into Vault
        uint256 depositAmount = vault.deposit(vaultBalance, msg.sender);

        // emit event
        emit AssetStaked(msg.sender, asset, depositAmount, referralId);
    }

    /**
     * @notice Internal function for unstaking
     */
    function _unstake(
        IERC20 asset,
        uint256 amount,
        address owner,
        address receiver,
        string calldata referralId
    )
        private
    {
        address assetAddress = address(asset);

        // get vault
        IKernelVault vault = _getVaultForAssetAddress(assetAddress);

        // withdraw from vault
        vault.withdraw(amount, owner, true);

        // transfer tokens
        SafeERC20.safeTransferFrom(asset, address(vault), receiver, amount);

        // emit event
        emit AssetUnstaked(msg.sender, assetAddress, amount, referralId);
    }
}
