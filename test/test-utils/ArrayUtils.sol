// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library ArrayUtils {
    ///
    function buildAddressArray() internal pure returns (address[] memory) {
        return new address[](0);
    }

    ///
    function add(address[] memory self, address el) internal pure returns (address[] memory) {
        return _pushToFixedLengthAddressesArray(self, el);
    }

    /**
     * @notice Push el in the end of input array, by creating a new memory array with length = input.length+1
     * @param input input array
     * @param el element to be added
     */
    function _pushToFixedLengthAddressesArray(
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
}
