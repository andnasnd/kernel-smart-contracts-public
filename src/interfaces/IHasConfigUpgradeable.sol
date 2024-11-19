// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface IHasConfigUpgradeable {
    /* External Functions ***********************************************************************************************/

    function getConfig() external view returns (address);
}
