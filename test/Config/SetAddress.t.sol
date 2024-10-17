// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

contract SetAddressTest is BaseTest {
    ///
    function test_SetAddress() public {
        IKernelConfig config_ = _deployConfig(tokens.wbnb);
        address demoAddress = makeAddr("foo");

        vm.startPrank(users.admin);

        // set AssetRegistry
        config_.setAddress("ASSET_REGISTRY", demoAddress);
        assertEq(config_.getAssetRegistry(), demoAddress);

        // set StakerGateway
        config_.setAddress("STAKER_GATEWAY", demoAddress);
        assertEq(config_.getStakerGateway(), demoAddress);
    }

    ///
    function test_RevertSetAddressIfAlreadySet() public {
        vm.startPrank(users.admin);
        address demoAddress = makeAddr("foo");

        string[] memory keys = _getSupportedAddressesKeys();

        for (uint256 i = 0; i < keys.length; i++) {
            string memory key = keys[i];

            // try to set address
            _expectRevertCustomErrorWithMessage(
                IKernelConfig.InvalidArgument.selector,
                string.concat("Setting address for key ", key, " is permitted only once")
            );
            config.setAddress(key, demoAddress);
        }
    }

    ///
    function test_RevertSetAddressIfNotManager() public {
        vm.startPrank(users.alice);
        address demoAddress = makeAddr("foo");

        string[] memory keys = _getSupportedAddressesKeys();

        for (uint256 i = 0; i < keys.length; i++) {
            string memory key = keys[i];

            _expectRevertMessage(
                string.concat(
                    "AccessControl: account ",
                    Strings.toHexString(users.alice),
                    " is missing role ",
                    Strings.toHexString(0, 32)
                )
            );
            config.setAddress(key, demoAddress);
        }
    }

    ///
    function test_RevertSetAddressIfAddressZero() public {
        IKernelConfig config_ = _deployConfig(tokens.wbnb);
        vm.startPrank(users.admin);

        string[] memory keys = _getSupportedAddressesKeys();

        for (uint256 i = 0; i < keys.length; i++) {
            string memory key = keys[i];

            // WBNB was already set when deployng Config
            if (Strings.equal(key, "WBNB_CONTRACT")) {
                continue;
            }

            _expectRevertCustomError(AddressHelper.InvalidZeroAddress.selector);
            config_.setAddress(key, address(0));
        }
    }

    /**
     * @notice Returns an array with all the keys of supported addresses to store
     */
    function _getSupportedAddressesKeys() private pure returns (string[] memory) {
        string[] memory keys = new string[](3);

        keys[0] = "ASSET_REGISTRY";
        keys[1] = "STAKER_GATEWAY";
        keys[2] = "WBNB_CONTRACT";

        return keys;
    }
}
