// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IKernelConfig is IAccessControlUpgradeable {
    /* Events ***********************************************************************************************************/

    event SetContract(string key, address addr);

    /* Errors ***********************************************************************************************************/

    /// A functionality was found paused
    error FunctionalityIsPaused(string);

    /// Function argument was invalid
    error InvalidArgument(string);

    /// The protocol was paused
    error ProtocolIsPaused();

    /// The address didn't ahve the ADMIN role
    error NotAdmin();

    /// The address didn't ahve the MANAGER role
    error NotManager();

    /// A sensitive key-value (eg. an address) in config was not stored
    error NotStored(string);

    /* External Functions ***********************************************************************************************/

    function check() external view returns (bool);

    function getAssetRegistry() external view returns (address);

    function getStakerGateway() external view returns (address);

    function getWBNBAddress() external view returns (address);

    function initialize(address adminAddr, address wbnbAddress) external;

    function isFunctionalityPaused(string calldata key) external view returns (bool);

    function isProtocolPaused() external view returns (bool);

    function pauseFunctionality(string calldata key) external;

    function requireFunctionalityVaultsDepositNotPaused() external view;

    function requireFunctionalityVaultsWithdrawNotPaused() external view;

    function requireRoleAdmin(address addr) external view;

    function requireRoleManager(address addr) external view;

    function setAddress(string calldata key, address addr) external;

    function unpauseFunctionality(string calldata key) external;
}
