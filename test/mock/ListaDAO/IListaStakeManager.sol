// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IListaStakeManager {
    struct WithdrawalRequest {
        uint256 uuid;
        uint256 amountInSnBnb;
        uint256 startTime;
    }

    function undelegateFrom(address _operator, uint256 _amount) external;
    function claimUndelegated(address _operator) external;
    // function getUserWithdrawalRequests(address _address) external returns (WithdrawalRequest[] memory);
}
