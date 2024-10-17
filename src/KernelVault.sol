// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { HasConfigUpgradeable } from "src/HasConfigUpgradeable.sol";
import { IKernelVault } from "src/interfaces/IKernelVault.sol";
import { KernelVaultStorage } from "src/KernelVaultStorage.sol";

/**
 * @title Vault
 * @notice One Vault is deployed for each asset managed by the protocol
 * @dev This contract is deployed using Beacon Proxy pattern
 */
contract KernelVault is Initializable, HasConfigUpgradeable, IKernelVault, KernelVaultStorage {
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

    /* Costructor *******************************************************************************************************/

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
     */
    function deposit(uint256 amount, address owner) external onlyFromStakerGateway onlyVaultsDepositNotPaused {
        // check if deposit limit is exceeded
        require(
            amount + _balance() <= depositLimit,
            DepositFailed(
                string.concat(
                    "Unable to deposit an amount of ",
                    Strings.toString(amount),
                    ": limit of ",
                    Strings.toString(depositLimit),
                    " exceeded"
                )
            )
        );

        // update balance
        balances[owner] += amount;
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
        asset = assetAddr;
        decimals = _getAssetDecimals(assetAddr);
    }

    /**
     * @notice Sets the deposit limit
     */
    function setDepositLimit(uint256 limit) external onlyManager {
        depositLimit = limit;
    }

    /**
     * @notice Withdraw from the Vault
     */
    function withdraw(uint256 amount, address owner) external onlyFromStakerGateway onlyVaultsWithdrawNotPaused {
        address stakerGateway = _config().getStakerGateway();

        // check if owner's balance is sufficient
        require(amount <= _balanceOf(owner), WithdrawFailed("Not enough balance to withdraw"));

        // decrease owner's balance
        balances[owner] -= amount;

        // update allowance of StakerGateway
        SafeERC20.safeDecreaseAllowance(IERC20(asset), stakerGateway, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(asset), stakerGateway, amount);
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

    /**
     * @notice Attempts to fetch the asset decimals
     */
    function _getAssetDecimals(address assetAddr) private view returns (uint8) {
        uint8 returnedDecimals = ERC20(assetAddr).decimals();

        // check if returnet value is valid
        require(
            returnedDecimals <= type(uint8).max,
            InvalidArgument(
                string.concat("Invalid number of decimals returned by asset ", Strings.toHexString(assetAddr))
            )
        );

        return returnedDecimals;
    }
}
