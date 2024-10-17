// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

abstract contract AssetRegistryStorage {
    /* State variables **************************************************************************************************/

    /// asset address to vault address
    mapping(address => address) internal assetToVault;

    /// storage gap for upgradeability
    uint256[50] private __gap;
}
