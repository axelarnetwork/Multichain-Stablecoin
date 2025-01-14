require('dotenv').config();
require('@nomicfoundation/hardhat-toolbox');
require('hardhat-contract-sizer');
require('hardhat-tracer');

const { task } = require('hardhat/config');
const chains = require('./chains.json');
const { getWallet } = require('./utils');
const Deployer = require('./artifacts/contracts/Deployer.sol/Deployer.json');
const Proxy = require('@openzeppelin/contracts/build/contracts/TransparentUpgradeableProxy.json');
const AccessControl = require('./artifacts/contracts/AccessControl.sol/AccessControl.json');
const Factory = require('./artifacts/contracts/TokenFactory.sol/TokenFactory.json');
const { create3DeployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/create3Deployer');

const create3DeployerAddress = '0x6513Aedb4D1593BA12e50644401D976aebDc90d8';

task('deployMoonbase', 'deploy deployer on remote chain (Moonbase for testing').setAction(async (taskArgs, hre) => {
    const wallet = getWallet(chains[1].rpc, hre);

    const implAccessControl = await create3DeployContract(create3DeployerAddress, wallet, AccessControl, 1, []);
    const implDeployer = await create3DeployContract(create3DeployerAddress, wallet, Deployer, 2, []);

    const proxyAccess = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 3, [
        implAccessControl.address,
        wallet.address,
        '0x',
    ]);
    const proxyDeployer = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 4, [
        implDeployer.address,
        wallet.address,
        '0x',
    ]);

    console.log(`proxyAccess ${proxyAccess.address}`);
    console.log(`proxyDeployer ${proxyDeployer.address}`);

    const AccessControlFactory = await ethers.getContractFactory('AccessControl');
    const DeployerFactory = await ethers.getContractFactory('Deployer');

    const proxyAccessControlInstance = await AccessControlFactory.attach(proxyAccess.address);
    const proxyDeployerInstance = await DeployerFactory.attach(proxyDeployer.address);

    await proxyAccessControlInstance.initialize(wallet.address);
    await proxyDeployerInstance.initialize(chains[1].its, proxyAccess.address, chains[1].gateway);
});

task('deployHomeCelo', 'deploy factory on home chain, (celo for testing)')
    .addParam('deployer', 'Deployer on dest chain')
    .setAction(async (taskArgs, hre) => {
        const wallet = getWallet(chains[0].rpc, hre);

        const implAccessControl = await create3DeployContract(create3DeployerAddress, wallet, AccessControl, 1, []);
        const implFactory = await create3DeployContract(create3DeployerAddress, wallet, Factory, 2, []);

        const proxyAccess = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 3, [
            implAccessControl.address,
            wallet.address,
            '0x',
        ]);

        const proxyFactory = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 4, [
            implFactory.address,
            wallet.address,
            '0x',
        ]);

        console.log(`celo contract address: ${proxyFactory.address}`);

        const AccessControlFactory = await ethers.getContractFactory('AccessControl');
        const TokenFactoryFactory = await ethers.getContractFactory('TokenFactory');

        const proxyAccessControlInstance = await AccessControlFactory.attach(proxyAccess.address);
        const proxyFactoryInstance = await TokenFactoryFactory.attach(proxyFactory.address);

        await proxyAccessControlInstance.initialize(wallet.address);

        await proxyFactoryInstance.initialize(
            chains[0].its,
            chains[0].gasService,
            chains[0].gateway,
            proxyAccess.address,
            taskArgs.deployer,
        );
    });

const config = {
    solidity: {
        version: '0.8.20',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200, // Adjust the runs according to how often you expect to call the functions
            },
        },
    },
    networks: {
        hardhat: {
            blockGasLimit: 10000000, // Set higher gas limit
            initialBaseFeePerGas: 0, // Can help with estimating gas
        },
        polygonLocalTest: {
            url: 'http://localhost:1545', // Replace with the actual RPC URL if not local
        },
        celo: {
            url: chains[0].rpc,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            chainId: chains[0].chainId,
        },
        moonbase: {
            url: chains[1].rpc,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            chainId: chains[1].chainId,
        },
        sepolia: {
            url: chains[2].rpc,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            chainId: chains[2].chainId,
        },
    },
    mocha: {
        timeout: 120000, // Timeout for all tests in milliseconds
    },
};

module.exports = config;
