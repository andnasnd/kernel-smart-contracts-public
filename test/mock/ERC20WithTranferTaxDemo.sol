// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Demo } from "test/mock/IERC20Demo.sol";

contract ERC20WithTranferTaxDemo is IERC20Demo, ERC20 {
    // tax percentage in bps
    uint256 tax;

    /// @param tax_ value of tax percentage in bps (1000 = 10%)
    constructor(string memory name_, string memory symbol_, uint256 tax_) ERC20(name_, symbol_) {
        require(tax <= 10_000, "tax cannot exceed 100%");
        tax = tax_;
    }

    ///
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    ///
    function _update(address from, address to, uint256 value) internal override {
        // calculate tax amount
        uint256 taxAmount = _calculatePercentage(value, tax);

        // simulate tax burn/transfer
        value = value - taxAmount;

        // transfer tokens
        ERC20._update(from, to, value);
    }

    ///
    function _calculatePercentage(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10_000);

        return amount * bps / 10_000;
    }
}
