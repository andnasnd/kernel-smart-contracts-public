// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title IHelioProvider
 * @author https://github.com/lista-dao/lista-dao-contracts/blob/master/contracts/ceros/interfaces/IHelioProviderV2.sol
 */
interface IHelioProvider {
    function provide() external payable returns (uint256);
    function provide(address _delegateTo) external payable returns (uint256);
    function release(address recipient, uint256 amount) external returns (uint256);
}
