// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { StakerGateway } from "src/StakerGateway.sol";

import { GenericUpgraded } from "test/mock/upgradeability/GenericUpgraded.sol";

/**
 * @title Mock StakerGateway Contract to test UUPS upgradeability
 */
contract StakerGatewayUpgraded is StakerGateway, GenericUpgraded {
    ///
    function version() public pure override(StakerGateway, GenericUpgraded) returns (string memory) {
        return GenericUpgraded.version();
    }
}
