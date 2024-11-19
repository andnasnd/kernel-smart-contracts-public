// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

library AddressUtils {
    ///
    function buildAddressArray(uint256 length, string memory prefix) internal pure returns (address[] memory) {
        address[] memory output = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            output[i] = address(
                uint160((uint256(keccak256(abi.encodePacked(string.concat(prefix, string(abi.encodePacked(i))))))))
            );
        }

        return output;
    }
}
