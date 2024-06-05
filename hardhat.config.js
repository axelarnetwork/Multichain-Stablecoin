require('dotenv').config();
const { task } = require('hardhat/config');
require('@nomicfoundation/hardhat-toolbox');
// require('@openzeppelin/hardhat-upgrades');
require('hardhat-contract-sizer');
// require('@nomicfoundation/hardhat-chai-matchers');
// require('hardhat-tracer');

const fs = require('fs-extra');
const chains = require('./chains.json');
const { getWallet } = require('./utils');
const Deployer = require('./artifacts/contracts/Deployer.sol/Deployer.json');
const Proxy = require('@openzeppelin/contracts/build/contracts/TransparentUpgradeableProxy.json');
const AccessControl = require('./artifacts/contracts/AccessControl.sol/AccessControl.json');
const { create3DeployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/create3Deployer');

const create3DeployerAddress = '0x6513Aedb4D1593BA12e50644401D976aebDc90d8';
// Task to clean up the .openzeppelin directory
task('cleanOpenZeppelin', 'Removes the .openzeppelin directory', async (_, hre) => {
    const directory = './.openzeppelin';
    if (fs.existsSync(directory)) {
        await fs.remove(directory);
        console.log('.openzeppelin directory removed successfully.');
    }
});

task('deployMoonbase', 'deploy deployer on remote chain (Moonbase for testing').setAction(async (taskArgs, hre) => {
    const wallet = getWallet(chains[1].rpc, hre);

    const implAccessControl = await create3DeployContract(create3DeployerAddress, wallet, AccessControl, 1010, []);
    const implDeployer = await create3DeployContract(create3DeployerAddress, wallet, Deployer, 1011, []);

    // const initData = ethers.utils.defaultAbiCoder.encode(
    //     ['address', 'address', 'address'],
    //     [chains[1].its, '0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE', chains[1].gateway],
    // );

    const proxyAccess = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 1012, [
        implAccessControl.address,
        wallet.address,
        '0x',
    ]);
    const proxyDeployer = await create3DeployContract(create3DeployerAddress, wallet, Proxy, 1013, [
        implDeployer.address,
        wallet.address,
        '0x',
    ]);

    console.log(`proxyAccess ${proxyAccess.address}`);
    console.log(`proxyDeployer ${proxyDeployer.address}`);

    const AccessControlFactory = await ethers.getContractFactory('AccessControl');
    const proxyAccessControlInstance = await AccessControlFactory.attach(proxyAccess.address);

    const DeployerFactory = await ethers.getContractFactory('Deployer');
    const proxyDeployerInstance = await DeployerFactory.attach(proxyDeployer.address);

    await proxyAccessControlInstance.initialize(wallet.address);
    await proxyDeployerInstance.initialize(chains[1].its, proxyAccess.address, chains[1].gateway);
});

/*
task('deployHomeCelo', 'deploy factory on home chain, (celo for testing)')
    .addParam('deployer', 'Deployer on dest chain')
    .setAction(async (taskArgs, hre) => {
        const connectedWallet = getWallet(chains[0].rpc, hre);
        const AccessControl = await ethers.getContractFactory('AccessControl');
        const TokenFactory = await ethers.getContractFactory('TokenFactory');
        const accessControlProxy = await upgrades.deployProxy(AccessControl, [connectedWallet.address], { initializer: 'initialize' });
        const tokenFactory = await upgrades.deployProxy(
            TokenFactory,
            [
                chains[0].its,
                chains[0].gasService,
                chains[0].gateway,
                accessControlProxy.target,
                taskArgs.deployer,
                'celo', // homeChain
            ],
            {
                initializer: 'initialize',
                unsafeAllow: ['constructor', 'state-variable-immutable'],
            },
        );

        console.log(`celo contract address: ${tokenFactory.target}`);
    });
*/
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
