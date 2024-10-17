// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

abstract contract KernelVaultStorage {
    /* State variables **************************************************************************************************/

    /// address of the ERC20 asset managed by the Vault
    address internal asset;

    /// number of decimals of the managed ERC20 asset
    uint8 internal decimals;

    /// balances of the users that deposited into the Vault
    mapping(address => uint256) internal balances;

    /// deposit limit
    uint256 public depositLimit;

    /// storage gap for upgradeability
    uint256[50] private __gap;
}
