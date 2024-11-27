// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { KernelConfigStorage } from "src/KernelConfigStorage.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IHasVersion } from "src/interfaces/IHasVersion.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

/**
 * @title Config
 * @notice Expose procotol configuration
 */
contract KernelConfig is AccessControlUpgradeable, UUPSUpgradeable, IKernelConfig, IHasVersion, KernelConfigStorage {
    /* Modifiers ********************************************************************************************************/

    /// @notice Reverts if user does not have ADMIN role
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /// @notice Reverts if user does not have PAUSER role
    modifier onlyPauser() {
        _checkRole(ROLE_PAUSER);
        _;
    }

    /// @notice Reverts if user does not have UPGRADER role
    modifier onlyUpgrader() {
        _checkRole(ROLE_UPGRADER);
        _;
    }

    /* Constructor ******************************************************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External Functions ***********************************************************************************************/

    /**
     * notice Returns true if every sensitive value has been configured and Config is production ready
     */
    function check() external view returns (bool) {
        require(_getAddress("ASSET_REGISTRY") != address(0), NotStored("AssetRegistry address not set"));
        require(_getAddress("STAKER_GATEWAY") != address(0), NotStored("StakerGateway address not set"));
        require(_getAddress("WBNB_CONTRACT") != address(0), NotStored("WBNB address not set"));

        return true;
    }

    /**
     * @notice Returns the address of the AssetRegistry
     */
    function getAssetRegistry() external view returns (address) {
        return _getAddress("ASSET_REGISTRY");
    }

    /**
     * @notice Returns the address of the StakerGateway
     */
    function getStakerGateway() external view returns (address) {
        return _getAddress("STAKER_GATEWAY");
    }

    /**
     *  @notice Returns the address of the WBNB token
     */
    function getWBNBAddress() external view returns (address) {
        return _getAddress("WBNB_CONTRACT");
    }

    /**
     * @notice Initialize function
     */
    function initialize(address adminAddr, address wbnbAddress) external initializer {
        // init
        AccessControlUpgradeable.__AccessControl_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();

        // grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddr);

        // set WBNB contract address
        _setAddress("WBNB_CONTRACT", wbnbAddress);
    }

    /**
     * @notice Returns true if a functionality is paused
     */
    function isFunctionalityPaused(string memory key) external view returns (bool) {
        return _isFunctionalityPaused(key);
    }

    /**
     * @notice Returns true if the protocol is paused
     */
    function isProtocolPaused() external view returns (bool) {
        return _isFunctionalityPaused("PROTOCOL");
    }

    /**
     * @notice Pauses a functionality
     * @param key string representing the key to pause
     * @dev Eg. pass key as "VAULTS_DEPOSIT", not as keccak256("VAULTS_DEPOSIT")
     */
    function pauseFunctionality(string calldata key) external onlyPauser {
        _setFunctionalityAsPaused(key, true);
    }

    /**
     * @notice Requires that functionality VAULTS_DEPOSIT is not paused
     */
    function requireFunctionalityVaultsDepositNotPaused() external view {
        // check if the whole protocol is paused
        _requireProtocolNotPaused();

        // check if functionality is paused
        _requireFunctionalityNotPaused("VAULTS_DEPOSIT");
    }

    /**
     * @notice Requires that functionality "VAULTS_WITHDRAW" is not paused
     */
    function requireFunctionalityVaultsWithdrawNotPaused() external view {
        // check if the whole protocol is paused
        _requireProtocolNotPaused();

        // check if functionality is paused
        _requireFunctionalityNotPaused("VAULTS_WITHDRAW");
    }

    /**
     * @notice Requires that an address has the ADMIN role
     */
    function requireRoleAdmin(address addr) external view {
        require(hasRole(DEFAULT_ADMIN_ROLE, addr), NotAdmin());
    }

    /**
     * @notice Requires that an address has the MANAGER role
     */
    function requireRoleManager(address addr) external view {
        require(hasRole(ROLE_MANAGER, addr), NotManager());
    }

    /**
     * @notice Requires that an address has the UPGRADER role
     */
    function requireRoleUpgrader(address addr) external view {
        require(hasRole(ROLE_UPGRADER, addr), NotUpgrader());
    }

    /**
     * @notice Sets an address
     */
    function setAddress(string calldata key, address addr) external onlyAdmin {
        _setAddress(key, addr);
    }

    /**
     * @notice Unpauses a functionality
     * @param key string representing the key to unpause
     * @dev Eg. pass key as "VAULTS_DEPOSIT", not keccak256("VAULTS_DEPOSIT")
     */
    function unpauseFunctionality(string calldata key) external onlyAdmin {
        _setFunctionalityAsPaused(key, false);
    }

    /**
     * @notice return version
     */
    function version() public pure virtual returns (string memory) {
        return "1.0";
    }

    /* Internal Functions ***********************************************************************************************/

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyUpgrader { }

    /* Private Functions ************************************************************************************************/

    /**
     * @notice Returns a stored address
     */
    function _getAddress(string memory key) private view returns (address) {
        return addresses[keccak256(abi.encodePacked(key))];
    }

    /**
     * @notice Returns an array with all the keys of supported addresses
     */
    function _getKeysSupportedForAddresses() private pure returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](3);

        keys[0] = ADDRESS_ASSET_REGISTRY;
        keys[1] = ADDRESS_STAKER_GATEWAY;
        keys[2] = ADDRESS_WBNB_CONTRACT;

        return keys;
    }

    /**
     * @notice Returns an array with all the keys of supported functionalities
     */
    function _getKeysSupportedForFunctionalities() private pure returns (bytes32[] memory) {
        bytes32[] memory keys = new bytes32[](3);

        keys[0] = FUNCTIONALITY_PROTOCOL;
        keys[1] = FUNCTIONALITY_VAULTS_DEPOSIT;
        keys[2] = FUNCTIONALITY_VAULTS_WITHDRAW;

        return keys;
    }

    /**
     * @notice Returns true if a given functionality is paused
     * @param key the functionality to check
     */
    function _isFunctionalityPaused(string memory key) private view returns (bool) {
        // check if key is supported
        _requireKeyIsSupportedForFunctionalities(key);

        return functionalityIsPaused[keccak256(abi.encodePacked(key))] == 1;
    }

    /**
     * @notice Returns true if {key} is a supported functionality key
     */
    function _isKeySupportedForAddresses(bytes32 key) private pure returns (bool) {
        bytes32[] memory keys = _getKeysSupportedForAddresses();

        uint256 length = keys.length;
        for (uint256 i = 0; i < length; i++) {
            if (key == keys[i]) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Returns true if {key} is a supported functionality key
     */
    function _isKeySupportedForFunctionalities(bytes32 key) private pure returns (bool) {
        bytes32[] memory keys = _getKeysSupportedForFunctionalities();

        uint256 length = keys.length;
        for (uint256 i = 0; i < length; i++) {
            if (key == keys[i]) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Reverts if functionality is paused
     */
    function _requireFunctionalityNotPaused(string memory key) private view {
        require(!_isFunctionalityPaused(key), FunctionalityIsPaused(string.concat("Functionality ", key, " is paused")));
    }

    /**
     * @notice Reverts if key is not a supported functionality key
     */
    function _requireKeyIsSupportedForFunctionalities(string memory key) private pure {
        bytes32 k = keccak256(abi.encodePacked(key));

        require(
            _isKeySupportedForFunctionalities(k),
            InvalidArgument(string.concat("Functionality key ", key, " is not supported"))
        );
    }

    /**
     * @notice Reverts if protocol is paused
     */
    function _requireProtocolNotPaused() private view {
        require(!_isFunctionalityPaused("PROTOCOL"), ProtocolIsPaused());
    }

    /**
     * @notice Sets an address in storage
     */
    function _setAddress(string memory key, address addr) private {
        bytes32 k = keccak256(abi.encodePacked(key));

        // check key is supported
        require(
            _isKeySupportedForAddresses(k), InvalidArgument(string.concat("Address key ", key, " is not supported"))
        );

        // check new value is not empty
        AddressHelper.requireNonZeroAddress(addr);

        // check previous address is empty (address can be set only once)
        require(
            addresses[k] == address(0),
            InvalidArgument(string.concat("Setting address for key ", key, " is permitted only once"))
        );

        // set new value
        addresses[k] = addr;

        // emit event
        emit SetContract(key, addr);
    }

    /**
     * @notice Pause or unpause a feature
     */
    function _setFunctionalityAsPaused(string memory key, bool isPaused) private {
        // convert bool into uint256
        uint256 newStatus = isPaused ? 1 : 0;

        // check if key is supported
        _requireKeyIsSupportedForFunctionalities(key);

        // pause or unpause
        functionalityIsPaused[keccak256(abi.encodePacked(key))] = newStatus;
    }
}
