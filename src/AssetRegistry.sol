// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { AssetRegistryStorage } from "src/AssetRegistryStorage.sol";
import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IHasVersion } from "src/interfaces/IHasVersion.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

/**
 * @title AssetRegistry
 * @notice Manage assets allowed in the protocol
 */
contract AssetRegistry is UUPSUpgradeable, HasConfigUpgradeable, IAssetRegistry, IHasVersion, AssetRegistryStorage {
    /* Modifiers ********************************************************************************************************/

    /// @notice Reverts if user does not have ADMIN role
    modifier onlyAdmin() {
        _config().requireRoleAdmin(msg.sender);
        _;
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
     * @notice Adds an asset to the registry
     * @param vault the address of the deployed vault managing that asset
     */
    function addAsset(address vault) external onlyAdmin {
        // retrieve asset managed by the Vault, ensuring that {vault} is an instance of Vault
        address asset = IKernelVault(vault).getAsset();

        // check asset is not already added
        require(!_hasAsset(asset), AssetAlreadyAdded());

        // add asset to registry
        assetToVault[asset] = vault;

        // update assets
        assets = AddressHelper.pushToFixedLengthAddressesArray(assets, asset);

        // emit event
        emit AssetAdded(asset, vault);
    }

    /**
     * @notice Returns the managed assets
     */
    function getAssets() external view returns (address[] memory) {
        return assets;
    }

    /**
     * @notice Returns the address of the vault for an asset
     * @param asset the address of the asset
     * @dev Reverts if the asset is not managed
     */
    function getVault(address asset) external view returns (address) {
        return address(_getVault(asset));
    }

    /**
     * @notice Returns the balance in the vault for an asset
     * @param asset the address of the asset
     * @dev Reverts if the asset is not managed
     */
    function getVaultBalance(address asset) external view returns (uint256) {
        return _getVault(asset).balance();
    }

    /**
     * @notice Returns the deposit limit of the vault for an asset
     * @param asset the address of the asset
     * @dev Reverts if the asset is not managed
     */
    function getVaultDepositLimit(address asset) external view returns (uint256) {
        return _getVault(asset).getDepositLimit();
    }

    /**
     * @notice Returns true if asset is managed by the registry
     */
    function hasAsset(address asset) external view returns (bool) {
        return _hasAsset(asset);
    }

    /**
     * @notice Initialize function
     */
    function initialize(address configAddr) external initializer {
        HasConfigUpgradeable.__HasConfig_init(configAddr);
        UUPSUpgradeable.__UUPSUpgradeable_init();
    }

    /**
     * @notice Removes an asset from the registry
     * @param asset the address of the asset
     */
    function removeAsset(address asset) external onlyAdmin {
        // check asset was already added
        require(_hasAsset(asset), AssetNotAdded());

        // check vault has no deposits
        address vault = assetToVault[asset];
        require(IKernelVault(vault).balance() == 0, VaultNotEmpty());

        // delete vault link
        delete assetToVault[asset];

        // update assets
        assets = AddressHelper.removeFromFixedLengthAddressesArray(assets, asset);

        // emit event
        emit AssetRemoved(asset, vault);
    }

    /**
     * @notice return version
     */
    function version() public pure virtual returns (string memory) {
        return "1.0";
    }

    /* Internal Functions ***********************************************************************************************/

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyUpgrader { }

    /* Private Functions ***********************************************************************************/

    /**
     * @notice Returns the vault for a given asset
     */
    function _getVault(address asset) private view returns (IKernelVault) {
        address vault = assetToVault[asset];

        // check vault exists
        require(
            address(vault) != address(0),
            VaultNotFound(string.concat("Vault not found for asset ", Strings.toHexString(asset)))
        );

        return IKernelVault(vault);
    }

    /**
     * @notice Returns true if asset is managed by the registry
     */
    function _hasAsset(address asset) private view returns (bool) {
        return assetToVault[asset] != address(0);
    }
}
