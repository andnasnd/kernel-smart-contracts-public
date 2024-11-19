// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseTest } from "test/BaseTest.sol";
import { ArrayUtils } from "test/test-utils/ArrayUtils.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

contract RemoveFromFixedLengthAddressesArrayTest is BaseTest {
    using ArrayUtils for address[];

    ///
    function test_RemoveFromFixedLengthAddressesArray_WithCardinality1() public {
        address a = makeAddr("a");
        address b = makeAddr("b");
        address c = makeAddr("c");
        address d = makeAddr("d");

        //
        address[] memory input = ArrayUtils.buildAddressArray().add(a).add(b).add(c).add(d);
        address[] memory output = AddressHelper.removeFromFixedLengthAddressesArray(input, b);

        assertEq(output.length, 3);
        _assertAddressArrayEq(output, ArrayUtils.buildAddressArray().add(a).add(c).add(d));
    }

    ///
    function test_RemoveFromFixedLengthAddressesArray_WithCardinality2() public {
        address a = makeAddr("a");
        address b = makeAddr("b");
        address c = makeAddr("c");
        address d = makeAddr("d");

        address[][] memory inputs = new address[][](4);
        inputs[0] = ArrayUtils.buildAddressArray().add(a).add(b).add(c).add(d).add(b);
        inputs[1] = ArrayUtils.buildAddressArray().add(b).add(a).add(c).add(b).add(d);
        inputs[2] = ArrayUtils.buildAddressArray().add(b).add(a).add(c).add(b).add(d).add(b);
        inputs[3] = ArrayUtils.buildAddressArray().add(b).add(a).add(c).add(d).add(b);

        // test removing el with cardinality 2
        for (uint256 i = 0; i < inputs.length; i++) {
            address[] memory input = inputs[i];
            address[] memory output = AddressHelper.removeFromFixedLengthAddressesArray(input, b);

            assertEq(output.length, 3);
            _assertAddressArrayEq(output, ArrayUtils.buildAddressArray().add(a).add(c).add(d));
        }
    }

    ///
    function test_RemoveFromFixedLengthAddressesArray_RevertIfNotFound() public {
        address a = makeAddr("a");
        address b = makeAddr("b");
        address c = makeAddr("c");
        address d = makeAddr("d");

        //
        address[] memory input = ArrayUtils.buildAddressArray().add(a).add(c).add(d);

        _expectRevertMessage(string.concat("Address ", Strings.toHexString(b), " was not found in input array"));
        AddressHelper.removeFromFixedLengthAddressesArray(input, b);
    }
}
