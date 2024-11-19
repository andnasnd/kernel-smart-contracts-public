// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title Generic upgraded contract
 */
contract GenericUpgraded {
    /**
     * @notice return version
     */
    function version() public pure virtual returns (string memory) {
        return "NEXT_VERSION";
    }
}
