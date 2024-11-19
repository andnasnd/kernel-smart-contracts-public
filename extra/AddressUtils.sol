// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library AddressUtils {
    ///
    function _buildArray0() internal pure returns (address[] memory) {
        address[] memory output = new address[](0);

        return output;
    }

    ///
    function _buildArray1(address a) internal pure returns (address[] memory) {
        address[] memory output = new address[](1);

        output[0] = a;

        return output;
    }

    ///
    function _buildArray2(address a, address b) internal pure returns (address[] memory) {
        address[] memory output = new address[](2);

        output[0] = a;
        output[1] = b;

        return output;
    }

    ///
    function _buildArray3(address a, address b, address c) internal pure returns (address[] memory) {
        address[] memory output = new address[](3);

        output[0] = a;
        output[1] = b;
        output[2] = c;

        return output;
    }

    ///
    function _buildArray4(address a, address b, address c, address d) internal pure returns (address[] memory) {
        address[] memory output = new address[](4);

        output[0] = a;
        output[1] = b;
        output[2] = c;
        output[3] = d;

        return output;
    }

    // Function to sort an array of addresses alphabetically
    function sortAddresses(address[] memory addresses) public pure returns (address[] memory) {
        uint256 length = addresses.length;

        // Bubble Sort algorithm
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                // Compare two addresses
                if (addresses[j] > addresses[j + 1]) {
                    // Swap if out of order
                    address temp = addresses[j];
                    addresses[j] = addresses[j + 1];
                    addresses[j + 1] = temp;
                }
            }
        }
        return addresses;
    }
}
