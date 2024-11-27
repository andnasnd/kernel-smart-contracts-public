// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

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

    /**
     * @notice Removes an element from an array
     */
    function removeAddressFromArray(address[] storage array, address value) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }
}
