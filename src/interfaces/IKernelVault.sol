// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

interface IKernelVault {
    /* Errors ***********************************************************************************************************/

    /// The Deposit failed
    error DepositFailed(string);

    /// Function argument was invalid
    error InvalidArgument(string);

    /// A function was called by an unauthorized sender
    error UnauthorizedCaller(string);

    /// The withdraw failed
    error WithdrawFailed(string);

    /* External Functions ***********************************************************************************************/

    function balance() external view returns (uint256);

    function balanceOf(address address_) external view returns (uint256);

    function deposit(uint256 amount, address owner) external;

    function getAsset() external view returns (address);

    function getDecimals() external view returns (uint8);

    function initialize(address assetAddr, address configAddr) external;

    function setDepositLimit(uint256 limit) external;

    function withdraw(uint256 amount, address owner) external;
}
