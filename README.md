# Stablecoin Demo

Corresponding code for Stablecoin Demo tutorial.

To operate this repo

1. Pass in `PRIVATE_KEY=""` in the `.env` file so that you can have a working wallet on testnet.
2. Deploy the `Deployer` on your remote chain by runing `hh deployMoonbase --network moonbase`
    - Currently the first task in `hardhat.config.js` will deploy this on Moonbase testnet.
3. Deployer `TokenFactory` on your home chain
    - Currently the second task in `hardhat.config.js` will deploy to Celo as your home chain.
4. Interact with TokenFactory either on the block explorer or the Hardhat CLI to deploy a native token

The completed code for this repo is in the `complete` branch

