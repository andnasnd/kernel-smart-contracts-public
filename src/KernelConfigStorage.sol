// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract KernelConfigStorage {
    /* Roles ************************************************************************************************************/

    /// Role "MANAGER"
    bytes32 public constant ROLE_MANAGER = keccak256("MANAGER");

    /// Role "PAUSER"
    bytes32 public constant ROLE_PAUSER = keccak256("PAUSER");

    /// Role "UPGRADER"
    bytes32 public constant ROLE_UPGRADER = keccak256("UPGRADER");

    // Pause all user functionalities at protocol level
    bytes32 internal constant FUNCTIONALITY_PROTOCOL = keccak256("PROTOCOL");

    /// Pause all Vaults deposits
    bytes32 internal constant FUNCTIONALITY_VAULTS_DEPOSIT = keccak256("VAULTS_DEPOSIT");

    /// Pause all Vaults withdraws
    bytes32 internal constant FUNCTIONALITY_VAULTS_WITHDRAW = keccak256("VAULTS_WITHDRAW");

    /* Addresses ********************************************************************************************************/

    //
    bytes32 internal constant ADDRESS_ASSET_REGISTRY = keccak256("ASSET_REGISTRY");
    bytes32 internal constant ADDRESS_CLIS_BNB_CONTRACT = keccak256("CLIS_BNB_CONTRACT");
    bytes32 internal constant ADDRESS_HELIO_PROVIDER_CONTRACT = keccak256("HELIO_PROVIDER_CONTRACT");
    bytes32 internal constant ADDRESS_STAKER_GATEWAY = keccak256("STAKER_GATEWAY");
    bytes32 internal constant ADDRESS_WBNB_CONTRACT = keccak256("WBNB_CONTRACT");

    /* State variables **************************************************************************************************/

    /// generic mapping to store addresses used in the protocol)
    mapping(bytes32 => address) internal addresses;

    /// store if a functionality is paused or not (using uint instead of bool)
    mapping(bytes32 pauseKey => uint256) internal functionalityIsPaused;

    /// storage gap for upgradeability
    uint256[50] private __gap;
}
