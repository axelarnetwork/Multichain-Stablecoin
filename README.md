# Stabelcoin Demo

Corresponding code for Stablecoin Demo tutorial.

To operate this repo

1. Pass in `PRIVATE_KEY=""` in the `.env` file so that you can have a working wallet on testnet.
2. Deploy the `Deployer` on your remote chain by runing `hh deployMoonbase --network moonbase`
    - Currently the first task in `hardhat.config.js` will deploy this on Moonbase testnet.
3. Deployer `TokenFactory` on your home chain
    - Currently the second task in `hardhat.config.js` will deploy to Celo as your home chain.
4. Interact with TokenFactory either on the block explorer or the Hardhat CLI to deploy a native token

If you choose to interact with the contract via Hardhat CLI you can follow these steps. In your cli:

1. `hh console --network celo`
2. `const Contract = await ethers.getContractFactory("TokenFactory")`
3. `const contract = await Contract.attach("<YOUR_DEPLOYED_ADDREESS>")`
4. `await contract.deployHomeNative("10000000000000000", "30000000000000000", {gasLimit: "10000000"})`
    - This will deploy a new NativeToken with a 1% burn rate and 3% transaction fee rate
5. `await contract.deployRemoteSemiNativeToken("moonbeam", {value: "1000000000000000000"})`
    - This will send a cross chain deployment of a Semi Native Token on the Moonbase testnet (Axelar still uses Moonbeam name to label Moonbase testnet)

At this point you will have tokens on both Celo and Moonbase that you can interact with and bridge from one chain to the other
NOTE: you must mint tokens first before you can bridge!

To upgrade your token to v2 in your CLI you must setup an instance of your `Deployer` contract (the same way you did for your `TokenFactory` contract). Then you can call the `upgradeSemiNativeToken()` function

1. `await contract.upgradeSemiNativeToken("<YOUR_PROXY_ADMIN_ADDRESS>")`


