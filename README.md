# Kernel Overview

This document provides a technical overview of the **Kernel** smart contract system, which facilitates token deposits and withdrawals to BEP20 asset-specific vaults.

The system is designed to manage user balances securely and efficiently via a **StakerGateway** acting as a mediator between the users and the **Vaults**.

This architecture supports a wide range of assets and ensures flexibility and security for all interactions.

#### Table of Contents

- [Actors](#actors)
- [Contracts](#contracts)
- [Additional Resources](#additional-resources)

---

# Actors

1. **User**: Can stake and unstake suported assets
1. **StakerGateway**: User's entrypoint, permits staking and unstaking
1. **KernelVault**: Manages users' deposits for each asset handled by the protocol

---

# Contracts

### **1. StakerGateway.sol**

The `StakerGateway` is the contract that interfaces directly with users, enabling them to stake and unstake tokens to and from the protocol. It acts as the intermediary that ensures proper authorization and routing of transactions between users and vaults.

**Key Features**

- **Stake**: User can stake an asset by depositing tokens into the related Vault

  ```solidity
  function stake(address asset, uint256 amount, string calldata referralId) external;

  function stakeNative(string calldata referralId) external payable;
  ```

- **Unstake**: Facilitates the unstaking of an asset by withdrawing tokens from the vault, ensures user eligibility and transfers tokens back to the user

  ```solidity
  function unstake(address asset, uint256 amount, string calldata referralId) external;

  function unstakeNative(uint256 amount, string calldata referralId) external;
  ```

- **Check Balance**: Check the amount of asset user holds in the protocol
  ```solidity
  function balanceOf(address asset, address owner) external view returns (uint256);
  ```

**Flows**

1. **Staking**
   1. User calls `stake()` function to stake an asset
   2. The `StakerGateway` transfers the tokens from `User` to the `KernelVault` responsible for the specific asset
   3. `KernelVault` increases `User`'s balance
1. **Untaking**
   1. User calls `unstake()` function to stake an asset
   2. The `StakerGateway` transfers the tokens from the `KernelVault` responsible for the specific asset to `User`
   3. `KernelVault` decreases `User`'s balance

## **2. KernelVault.sol**

The `KernelVault` is responsible for tracking the token balance of users within the system.
It offers functionality for deposits and withdrawals and ensures that only `StakerGateway` can interact with the vaults.

One **KernelVault** is deployed for each asset. Vaults are deployed using the Beacon proxy pattern.

**Key Features**

- **Deposit**: User can deposit tokens until the vault reaches a pre-defined limit, increasing his balance
- **Withdraw**: User can withdraw tokens from the Vault, decreasing his balance

**Security Considerations**

- Only `StakerGateway` can call `KernelVault.sol`'s functions, ensuring secure and controlled access
- User balances are securely stored within the vault, preventing unauthorized access or manipulation

### **3. AssetRegistry.sol**

`AssetRegistry` manages the mapping of assets to their respective vaults. It stores information on supported assets and ensures that the system only processes transactions for valid asset-vault pairs.

**Key Features**

- **Asset-to-Vault Mapping**: Keeps track of the vault associated with each supported asset
- **Asset Validation**: Ensures that only supported assets are processed in the system

### **4. KernelConfig.sol**

`KernelConfig` handles the overall configuration of the protocol, including role-based access control and functionalities pausing.

The contract allows pausing of `Deposits to all Vaults` or `Withdrawals from all Vaults` independently, or pausing `all users' functions at the same time at protocol level`.

**Key Roles**

- **Admin**: Manages roles and perform critical tasks
- **Manager**: Responsible for managing system configurations, such as adding vaults and assets
- **Pauser**: Has the ability to pause the entire protocol or some specific features like deposit and withdrawa in case of emergency

# Additional Resources

- Deployed contracts
    - [Kernel Protocol on BSC Mainnet](doc/contract-address/Mainnet.md)
    - [Kernel Protocol on BSC Testnet](doc/contract-address/Testnet.md)
- [How to Deploy](doc/Deploy.md)