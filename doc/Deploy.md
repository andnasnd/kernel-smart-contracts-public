# How to Deploy

This guide shows the steps to deploy Kernel Protocol on various blockchains.

### How to deploy Kernel Protocol

On __BSC Mainnet__:

        forge clean && forge script script/prod/DeployToBscMainnet.s.sol \
            --fork-url <rpc url> \
            --broadcast \
            --slow \
            --verify \
            --etherscan-api-key <etherscan API Key> \
            --account <Foundry Wallet account>

On  a __BSC Testnet__:

        forge clean && forge script script/prod/DeployToBscTestnet.s.sol \
            --fork-url <rpc url> \
            --broadcast \
            --slow \
            --verify \
            --etherscan-api-key <etherscan API Key> \
            --account <Foundry Wallet account>

On  __Sepolia Testnet__ (including BSC Testnet):

        forge clean && forge script script/prod/DeployToSepoliaTestnet.s.sol \
            --fork-url <rpc url> \
            --broadcast \
            --slow \
            --verify \
            --etherscan-api-key <etherscan API Key> \
            --account <Foundry Wallet account>

### How to add an Asset

Follow these steps to support a new ERC20 Asset.

1. Deploy a new KernelVault
    
        forge clean && forge script script/prod/DeployKernelVault.s.sol \
            -s "run(address, address, address)" \
            <KernelConfiguration> \
            <KernelVault Beacon> \
            <Asset> \
            --fork-url <rpc url> \
            --broadcast \
            --slow \
            --verify \
            --etherscan-api-key <etherscan API Key> \
            --account <Foundry Wallet account>

2. Call `AssetRegistry::addAsset(<Vault address>)`