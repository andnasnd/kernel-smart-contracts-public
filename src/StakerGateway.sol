// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IStakerGateway } from "src/interfaces/IStakerGateway.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { IWBNB } from "src/interfaces/IWBNB.sol";
import { StakerGatewayStorage } from "src/StakerGatewayStorage.sol";

/**
 * @title StakerGateway
 * @notice Main entry point of the protocol for staking and unstaking
 */
contract StakerGateway is ReentrancyGuardUpgradeable, HasConfigUpgradeable, IStakerGateway, StakerGatewayStorage {
    /* Costructor *******************************************************************************************************/

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
        return address(_getVaultForAssetAddress(asset));
    }

    /**
     * @notice Stakes an ERC20 asset in the protocol
     * @param asset address of the ERC20 token to stake
     * @param amount amount to stake
     * @dev Staker must provide prior approval to this contract for transfering ERC20 asset
     */
    function stake(address asset, uint256 amount, string calldata referralId) external nonReentrant {
        _stake(asset, msg.sender, amount, referralId);
    }

    /**
     * @notice Stakes native tokens in the protocol
     * @dev Internally converts $BNB into $WBNB and deposits them to the Vault
     */
    function stakeNative(string calldata referralId) external payable nonReentrant {
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
    function unstake(address asset, uint256 amount, string calldata referralId) external nonReentrant {
        _unstake(IERC20(address(asset)), amount, msg.sender, msg.sender, referralId);
    }

    /**
     * @notice Unstakes native tokens from the protocol
     * @dev Internally converts $WBNB back to $BNB and sends them to user
     */
    function unstakeNative(uint256 amount, string calldata referralId) external nonReentrant {
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
     * @notice Enables receiving native tokens
     * @dev This is necessary to withdraw $WBNB from the Vault and transfer them to the StakerGateway (and then to the
     * user) because WBNB.withdraw() doesn't let us specify msg.sender as receiver.
     */
    receive() external payable {
        // TODO: receive() should be allowed only when calling WBNB.withdraw
        // but require(msg.sender == address(this)); goes outOfGas
    }

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

        address assetAddress = address(asset);

        // get vault
        IKernelVault vault = _getVaultForAssetAddress(assetAddress);

        // transfer tokens to Vault
        SafeERC20.safeTransferFrom(asset_, source, address(vault), amount);

        // register deposit into Vault
        vault.deposit(amount, msg.sender);

        // emit event
        emit AssetStaked(msg.sender, assetAddress, amount, referralId);
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
        vault.withdraw(amount, owner);

        // transfer tokens
        SafeERC20.safeTransferFrom(asset, address(vault), receiver, amount);

        // emit event
        emit AssetUnstaked(msg.sender, assetAddress, amount, referralId);
    }
}
