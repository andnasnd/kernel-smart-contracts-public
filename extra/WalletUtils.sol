// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";

library WalletUtils {
    ///
    function _buildArray0() internal pure returns (Vm.Wallet[] memory) {
        Vm.Wallet[] memory output = new Vm.Wallet[](0);

        return output;
    }

    ///
    function _buildArray1(Vm.Wallet memory a) internal pure returns (Vm.Wallet[] memory) {
        Vm.Wallet[] memory output = new Vm.Wallet[](1);

        output[0] = a;

        return output;
    }

    ///
    function _buildArray2(Vm.Wallet memory a, Vm.Wallet memory b) internal pure returns (Vm.Wallet[] memory) {
        Vm.Wallet[] memory output = new Vm.Wallet[](2);

        output[0] = a;
        output[1] = b;

        return output;
    }

    ///
    function _buildArray3(
        Vm.Wallet memory a,
        Vm.Wallet memory b,
        Vm.Wallet memory c
    )
        internal
        pure
        returns (Vm.Wallet[] memory)
    {
        Vm.Wallet[] memory output = new Vm.Wallet[](3);

        output[0] = a;
        output[1] = b;
        output[2] = c;

        return output;
    }

    ///
    function _buildArray4(
        Vm.Wallet memory a,
        Vm.Wallet memory b,
        Vm.Wallet memory c,
        Vm.Wallet memory d
    )
        internal
        pure
        returns (Vm.Wallet[] memory)
    {
        Vm.Wallet[] memory output = new Vm.Wallet[](4);

        output[0] = a;
        output[1] = b;
        output[2] = c;
        output[3] = d;

        return output;
    }

    // Function to sort an array of Wallets based on the address (addr)
    function sortWallets(Vm.Wallet[] memory wallets) public pure returns (Vm.Wallet[] memory) {
        uint256 length = wallets.length;

        // Bubble Sort algorithm
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                // Compare two Wallet addresses
                if (wallets[j].addr > wallets[j + 1].addr) {
                    // Swap if out of order
                    Vm.Wallet memory temp = wallets[j];
                    wallets[j] = wallets[j + 1];
                    wallets[j + 1] = temp;
                }
            }
        }
        return wallets; // Return the sorted array
    }

    /// @notice Converts an array of Wallet[] into address[]
    function walletsToAddresses(Vm.Wallet[] memory wallets) internal pure returns (address[] memory) {
        address[] memory output = new address[](wallets.length);

        for (uint256 i = 0; i < wallets.length; i++) {
            output[i] = wallets[i].addr;
        }

        return output;
    }
}
