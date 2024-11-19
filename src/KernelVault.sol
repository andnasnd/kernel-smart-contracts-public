// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { KernelVaultStorage } from "src/KernelVaultStorage.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { AddressHelper } from "src/libraries/AddressHelper.sol";

/**
 * @title Vault
 * @notice One Vault is deployed for each asset managed by the protocol
 * @dev This contract is deployed using Beacon Proxy pattern
 */
contract KernelVault is HasConfigUpgradeable, IKernelVault, KernelVaultStorage {
    /* Modifiers ********************************************************************************************************/

    /// @notice Reverts if sender is not the StakerGateway
    modifier onlyFromStakerGateway() {
        require(
            msg.sender == _config().getStakerGateway(),
            UnauthorizedCaller(
                string.concat("Sender ", Strings.toHexString(msg.sender), " is not an authorized caller")
            )
        );
        _;
    }

    /// @notice Reverts if vaults deposits are paused
    modifier onlyVaultsDepositNotPaused() {
        _config().requireFunctionalityVaultsDepositNotPaused();
        _;
    }

    /// @notice Reverts if vaults withdrawal are paused
    modifier onlyVaultsWithdrawNotPaused() {
        _config().requireFunctionalityVaultsWithdrawNotPaused();
        _;
    }

    /// @notice Reverts if user does not have MANAGER role
    modifier onlyManager() {
        _config().requireRoleManager(msg.sender);
        _;
    }

    /* Constructor ******************************************************************************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* External Functions ***********************************************************************************************/

    /**
     * @notice Returns the Vault's balance of the managed asset
     */
    function balance() external view returns (uint256) {
        return _balance();
    }

    /**
     * @notice Returns the balance of the managed asset for a given owner
     */
    function balanceOf(address address_) external view returns (uint256) {
        return _balanceOf(address_);
    }

    /**
     * @notice Deposit to the Vault
     * @param vaultBalanceBefore the Vault balance before registering deposit
     * @dev Tokens transfer must happen before calling deposit()
     * @dev The amount deposited is not passed as argument, but inferred by balance after transferring tokens and
     * {vaultBalanceBefore}
     */
    function deposit(
        uint256 vaultBalanceBefore,
        address owner
    )
        external
        onlyFromStakerGateway
        onlyVaultsDepositNotPaused
    {
        uint256 depositAmount = _balance() - vaultBalanceBefore;
        require(depositAmount > 0, DepositFailed("Tokens were not transferred to Vault before calling deposit()"));

        // check if deposit limit is exceeded
        require(
            _balance() <= depositLimit,
            DepositFailed(
                string.concat(
                    "Unable to deposit an amount of ",
                    Strings.toString(depositAmount),
                    ": limit of ",
                    Strings.toString(depositLimit),
                    " exceeded"
                )
            )
        );

        // update balance
        balances[owner] += depositAmount;
    }

    /**
     * @notice Returns the address of the asset managed by this vault
     */
    function getAsset() external view returns (address) {
        return address(asset);
    }

    /**
     * @notice Returns the number of decimals of the asset managed by this vault
     */
    function getDecimals() external view returns (uint8) {
        return decimals;
    }

    /**
     * @notice Initialize function
     */
    function initialize(address assetAddr, address configAddr) external initializer {
        // init
        HasConfigUpgradeable.__HasConfig_init(configAddr);

        //
        AddressHelper.requireNonZeroAddress(assetAddr);
        asset = assetAddr;
        decimals = IERC20Metadata(asset).decimals();
    }

    /**
     * @notice Returns the deposit limit
     */
    function getDepositLimit() external view returns (uint256) {
        return depositLimit;
    }

    /**
     * @notice Sets the deposit limit
     */
    function setDepositLimit(uint256 limit) external onlyManager {
        depositLimit = limit;
    }

    /**
     * @notice Withdraw from the Vault
     * @param amount the amount to withdraw
     * @param owner the owner of the tokens
     * @param requireApproval whether to provide token approval to the stakerGateway
     */
    function withdraw(
        uint256 amount,
        address owner,
        bool requireApproval
    )
        external
        onlyFromStakerGateway
        onlyVaultsWithdrawNotPaused
    {
        address stakerGateway = _config().getStakerGateway();

        // check if owner's balance is sufficient
        require(amount <= _balanceOf(owner), WithdrawFailed("Not enough balance to withdraw"));

        // decrease owner's balance
        balances[owner] -= amount;

        // update allowance of StakerGateway
        if (requireApproval) {
            SafeERC20.forceApprove(IERC20(asset), stakerGateway, amount);
        }
    }

    /* Private Functions ************************************************************************************************/

    /**
     * @notice Returns the Vault's balance of the managed asset
     */
    function _balance() private view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the balance of the managed asset for a given owner
     */
    function _balanceOf(address address_) private view returns (uint256) {
        return balances[address_];
    }
}
