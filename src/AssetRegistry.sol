// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { AssetRegistryStorage } from "src/AssetRegistryStorage.sol";
import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { IAssetRegistry } from "src/interfaces/IAssetRegistry.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";

/**
 * @title AssetRegistry
 * @notice Manage assets allowed in the protocol
 */
contract AssetRegistry is Initializable, HasConfigUpgradeable, IAssetRegistry, AssetRegistryStorage {
    /* Modifiers ********************************************************************************************************/

    /// @notice Reverts if user does not have ADMIN role
    modifier onlyAdmin() {
        _config().requireRoleAdmin(msg.sender);
        _;
    }

    /// @notice Reverts if user does not have MANAGER role
    modifier onlyManager() {
        _config().requireRoleManager(msg.sender);
        _;
    }

    /* Costructor *******************************************************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External Functions ***********************************************************************************************/

    /**
     * @notice Adds an asset to the registry
     * @param vault the address of the deployed vault managing that asset
     */
    function addAsset(address vault) external onlyManager {
        // retrieve asset managed by the Vault, ensuring that {vault} is an instance of Vault
        address asset = IKernelVault(vault).getAsset();

        // check asset is not already added
        require(!_hasAsset(asset), AssetAlreadyAdded());

        // add asset to registry
        assetToVault[asset] = vault;

        // emit event
        emit AssetAdded(asset, vault);
    }

    /**
     * @notice Returns the address of the vault for an asset
     * @param asset the address of the asset
     * @dev Reverts if the asset is not managed
     */
    function getVault(address asset) external view returns (address) {
        address vault = assetToVault[asset];

        // check vault exists
        require(
            address(vault) != address(0),
            VaultNotFound(string.concat("Vault not found for asset ", Strings.toHexString(asset)))
        );

        return vault;
    }

    /**
     * @notice Initialize function
     */
    function initialize(address configAddr) external initializer {
        HasConfigUpgradeable.__HasConfig_init(configAddr);
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

        // emit event
        emit AssetRemoved(asset, vault);
    }

    /* Private Functions ***********************************************************************************/

    /**
     * @notice Return true if asset is found in the registry
     */
    function _hasAsset(address asset) private view returns (bool) {
        return assetToVault[asset] != address(0);
    }
}
