// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { IHasConfigUpgradeable } from "src/interfaces/IHasConfigUpgradeable.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

/**
 * @title HasConfigUpgradeable
 * @notice Extending this contract links the child to a Config instance
 */
abstract contract HasConfigUpgradeable is Initializable, IHasConfigUpgradeable {
    /* State variables **************************************************************************************************/

    address private configAddress;

    /// storage gap for upgradeability
    uint256[50] private __gap;

    /* Costructor *******************************************************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External Functions ***********************************************************************************************/

    /**
     * @notice Returns the address of the Config instance
     */
    function getConfig() external view returns (address) {
        return configAddress;
    }

    /* Internal Functions ***********************************************************************************************/

    /**
     * @notice Sets the value for {configAddress}
     */
    function __HasConfig_init(address configAddr) internal onlyInitializing {
        __HasConfig_init_unchained(configAddr);
    }

    /**
     * @notice Unchained initializer
     */
    function __HasConfig_init_unchained(address addr) internal onlyInitializing {
        AddressHelper.requireNonZeroAddress(addr);

        configAddress = addr;
    }

    /**
     * @notice Returns the Config instance
     */
    function _config() internal view returns (IKernelConfig) {
        return IKernelConfig(configAddress);
    }
}
