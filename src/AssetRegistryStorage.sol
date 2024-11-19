// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract AssetRegistryStorage {
    /* State variables **************************************************************************************************/

    /// asset address to vault address
    mapping(address => address) internal assetToVault;

    /// list of managed assets
    address[] internal assets;

    /// storage gap for upgradeability
    uint256[50] private __gap;
}
