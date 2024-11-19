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
     * @notice Push el in the end of input array, by creating a new memory array with length = input.length+1
     * @param input input array
     * @param el element to be added
     */
    function pushToFixedLengthAddressesArray(
        address[] memory input,
        address el
    )
        internal
        pure
        returns (address[] memory)
    {
        address[] memory output = new address[](input.length + 1);

        for (uint256 i = 0; i < input.length;) {
            output[i] = input[i];

            unchecked {
                i++;
            }
        }

        output[output.length - 1] = el;

        return output;
    }

    /**
     * @notice Remove el from the input array, by creating a new memory array with length = input.length-1
     * @param input input array
     * @param el element to be removed
     */
    function removeFromFixedLengthAddressesArray(
        address[] memory input,
        address el
    )
        internal
        pure
        returns (address[] memory)
    {
        // count how many addresses are different from {el}
        uint256 occurrences = 0;

        for (uint256 i = 0; i < input.length;) {
            if (input[i] == el) {
                occurrences++;
            }

            unchecked {
                i++;
            }
        }

        require(occurrences > 0, string.concat("Address ", Strings.toHexString(el), " was not found in input array"));

        // create a new array with the required size
        address[] memory output = new address[](input.length - occurrences);

        // populate the new array with addresses that are not equal to {el}
        uint256 j = 0;

        for (uint256 i = 0; i < input.length;) {
            if (input[i] != el) {
                output[j] = input[i];

                unchecked {
                    j++;
                }
            }

            unchecked {
                i++;
            }
        }

        //
        return output;
    }
}
