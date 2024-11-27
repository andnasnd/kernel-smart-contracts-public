// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterVault {
    // function withdrawETH(address account, uint256 amount) external returns (uint256);
    // function depositETH() external payable returns (uint256);
    // function feeReceiver() external returns (address payable);
    // function withdrawalFee() external view returns (uint256);
    // function strategyParams(address strategy) external view returns (bool active, uint256 allocation, uint256 debt);
    // function withdrawInTokenFromStrategy(
    //     address strategy,
    //     address recipient,
    //     uint256 amount
    // )
    //     external
    //     returns (uint256);

    function depositAllToStrategy(address strategy) external;
}
