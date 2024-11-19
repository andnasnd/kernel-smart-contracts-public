// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract StakerGatewayStorage {
    /* Constants ********************************************************************************************************/

    uint256 internal constant RECEIVE_NATIVE_TOKENS_FALSE = 0;
    uint256 internal constant RECEIVE_NATIVE_TOKENS_TRUE = 1;

    /* State variables **************************************************************************************************/

    uint256 internal canReceiveNativeTokens;

    /// storage gap for upgradeability
    uint256[50] private __gap;
}
