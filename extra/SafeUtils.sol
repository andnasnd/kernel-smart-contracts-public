// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/Test.sol";

import { Safe } from "@safe-smart-account/contracts/Safe.sol";
import { SafeProxy } from "@safe-smart-account/contracts/proxies/SafeProxy.sol";
import { SafeProxyFactory } from "@safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { Enum } from "@safe-smart-account/contracts/common/Enum.sol";

import { AddressUtils } from "extra/AddressUtils.sol";
import { WalletUtils } from "extra/WalletUtils.sol";

library SafeUtils {
    uint256 constant VALUE = 0;
    Enum.Operation constant OPERATION = Enum.Operation.Call;
    uint256 constant SAFE_TX_GAS = 0;
    uint256 constant BASE_GAS = 0;
    uint256 constant GAS_PRICE = 0;
    address constant GAS_TOKEN = address(0);
    address payable constant REFUND_RECEIVER = payable(address(0));

    /// @notice Approve a transaction hash by 1 owner
    function approveTransactionHash(Safe self, bytes32 safeTxHash) internal {
        self.approveHash(safeTxHash);
    }

    /// @notice Build signature from 1 owner
    function buildSignature(Vm vm, Vm.Wallet memory owner, bytes32 safeTxHash) internal returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner, safeTxHash);

        return abi.encodePacked(r, s, v);
    }

    /// @notice Build signatures from all owners
    function buildSignatures(Vm vm, Vm.Wallet[] memory owners, bytes32 safeTxHash) internal returns (bytes memory) {
        bytes memory signatures = "";

        Vm.Wallet[] memory sortedOwners = WalletUtils.sortWallets(owners);

        for (uint256 i; i < sortedOwners.length; ++i) {
            signatures = bytes.concat(signatures, buildSignature(vm, sortedOwners[i], safeTxHash));
        }

        return signatures;
    }

    ///
    function deploySafe(Vm.Wallet[] memory owners) internal returns (Safe) {
        address[] memory ownerAddresses = WalletUtils.walletsToAddresses(owners);

        // TODO: one should be sufficient
        Safe singleton = new Safe();

        // TODO: one should be sufficient
        SafeProxyFactory proxyFactory = new SafeProxyFactory();

        // init data
        bytes memory initData = abi.encodeWithSelector(
            Safe.setup.selector,
            ownerAddresses,
            ownerAddresses.length,
            address(0),
            "",
            address(0),
            address(0),
            0,
            payable(address(0))
        );

        // deploy Safe proxy
        uint256 nonce = uint256(keccak256(abi.encode("SAFE", 0)));
        SafeProxy proxy = proxyFactory.createProxyWithNonce(address(singleton), initData, nonce);

        //
        return Safe(payable(address(proxy)));
    }

    /// @notice execute a transaction
    /// @dev all owners must have approved transaction hash previously
    function executeApprovedTransaction(Safe self, address to, bytes memory data) internal {
        // get owners (sorted)
        address[] memory owners = AddressUtils.sortAddresses(self.getOwners());

        // get threshold
        uint256 threshold = self.getThreshold();

        // build signature
        bytes memory signatures = new bytes(threshold * 65);

        // populate each 65-byte slot
        for (uint256 i = 0; i < threshold; i++) {
            bytes32 r = bytes32(uint256(uint160(owners[i])));
            bytes32 s = bytes32(uint256(0x0));
            uint8 v = 1;

            // store r, s, v in the correct positions
            assembly {
                mstore(add(signatures, add(32, mul(i, 65))), r) // Store `r`
                mstore(add(signatures, add(64, mul(i, 65))), s) // Store `s`
                mstore8(add(signatures, add(96, mul(i, 65))), v) // Store `v`
            }
        }

        // execute transaction
        bool success = executeTransaction(self, to, data, signatures);

        // check result
        require(success == true, "Transaction execution failed.");
    }

    /// @notice executes a transaction
    function executeTransaction(
        Safe self,
        address to,
        bytes memory data,
        bytes memory signatures
    )
        internal
        returns (bool)
    {
        return self.execTransaction(
            to, VALUE, data, OPERATION, SAFE_TX_GAS, BASE_GAS, GAS_PRICE, GAS_TOKEN, REFUND_RECEIVER, signatures
        );
    }

    /// @notice executes a transaction collecting the signatures of all the owners
    function executeTransactionCollectingAllSignaturesAtOnce(
        Safe self,
        Vm vm,
        Vm.Wallet[] memory owners,
        address to,
        bytes memory data
    )
        internal
        returns (bool)
    {
        // get transaction hash
        bytes32 safeTxHash = getTransactionHash(self, to, data);

        // build signatures for all owners
        bytes memory signatures = buildSignatures(vm, owners, safeTxHash);

        // esecute transaction immediately
        return executeTransaction(self, to, data, signatures);
    }

    ///
    function getDeployedSafe(address safe) internal pure returns (Safe) {
        return Safe(payable(address(safe)));
    }

    ///
    function getTransactionHash(Safe self, address to, bytes memory data) internal view returns (bytes32) {
        return self.getTransactionHash(
            to, VALUE, data, OPERATION, SAFE_TX_GAS, BASE_GAS, GAS_PRICE, GAS_TOKEN, REFUND_RECEIVER, self.nonce()
        );
    }

    /// @return Safe Transaction hash
    function proposeTransaction(Safe self, address to, bytes memory data) internal returns (bytes32) {
        // get transaction hash
        bytes32 safeTxHash = getTransactionHash(self, to, data);

        // approve transaction hash by 1 owner
        approveTransactionHash(self, safeTxHash);

        //
        return safeTxHash;
    }
}
