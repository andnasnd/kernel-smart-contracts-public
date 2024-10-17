// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BaseTest } from "test/BaseTest.sol";
import { IKernelConfig } from "src/interfaces/IKernelConfig.sol";

contract GetStakerGatewayTest is BaseTest {
    /// retrieve correctly config.getStakerGateway()
    function test_GetStakerGateway() public view {
        assertEq(config.getStakerGateway(), address(stakerGateway));
    }
}
