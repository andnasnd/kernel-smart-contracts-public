// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

/**
 * @title AddressHelper
 * @notice Useful functions to handle addresses
 */
library AddressHelper {
    /* Errors ***********************************************************************************************************/

    // Address was empty
    error InvalidZeroAddress();

    /**
     * @notice Reverts if an address is zero
     * @param addr address to check
     */
    function requireNonZeroAddress(address addr) internal pure {
        require(addr != address(0), InvalidZeroAddress());
    }
}
