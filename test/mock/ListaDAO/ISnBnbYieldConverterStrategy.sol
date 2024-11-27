// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISnBnbYieldConverterStrategy {
    struct UserWithdrawRequest {
        address recipient;
        uint256 amount; //BNB
        uint256 snBnbAmount;
        uint256 triggerTime;
    }

    function batchWithdraw() external;
    function claimNextBatchAndDistribute(uint256 maxNumRequests)
        external
        returns (bool foundClaimableReq, uint256 reqCount);

    function getWithdrawRequests(address account) external view returns (UserWithdrawRequest[] memory requests);
    // function distributeManual(address recipient) external;
    // function bnbToDistribute() external returns (uint256);
}
