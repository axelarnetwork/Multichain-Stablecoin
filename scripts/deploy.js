'use strict';

const { create3DeployContract, create3DeployAndInitContract } = require('./create3Deployer');

const IUpgradable = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/interfaces/IUpgradable.sol/IUpgradable.json');
// for deploying upgradable contracts with Proxy via CREATE3 method
async function deployCreate3Upgradable(
    hre,
    create3DeployerAddress,
    wallet,
    implementationJson,
    proxyJson,
    implementationConstructorArgs = [],
    additionalProxyConstructorArgs = [],
    setupParams = '0x',
    key = Date.now().toString(),
    gasLimit = null,
    env = 'testnet',
    chain = 'ethereum',
    shouldVerifyContract = false,
) {
    const implementationFactory = new hre.ethers.ContractFactory(implementationJson.abi, implementationJson.bytecode, wallet);

    const implementation = await implementationFactory.deploy(...implementationConstructorArgs);
    await implementation.deployed();

    const proxy = await create3DeployContract(
        hre,
        create3DeployerAddress,
        wallet,
        proxyJson,
        key,
        [implementation.address, wallet.address, setupParams, ...additionalProxyConstructorArgs],
        gasLimit,
    );

    return new hre.ethers.Contract(proxy.address, implementationJson.abi, wallet);
}

// for deploying upgradable contracts with InitProxy via CREATE3 method
async function deployCreate3InitUpgradable(
    hre,
    create3DeployerAddress,
    wallet,
    implementationJson,
    proxyJson,
    implementationConstructorArgs = [],
    proxyConstructorArgs = [],
    initArgs = [],
    setupParams = '0x',
    key = Date.now(),
    gasLimit = null,
    env = 'testnet',
    chain = 'ethereum',
    shouldVerifyContract = false,
) {
    const implementationFactory = new hre.ethers.ContractFactory(implementationJson.interface, implementationJson.bytecode, wallet);
    const implementation = await implementationFactory.deploy(...implementationConstructorArgs);
    await implementation.deployed();
    const salt = hre.ethers.utils.keccak256(key);
    const proxy = await create3DeployAndInitContract(
        hre,
        create3DeployerAddress,
        wallet,
        proxyJson,
        salt,
        proxyConstructorArgs,
        initArgs,
        gasLimit,
    );

    return new hre.ethers.Contract(proxy.address, implementationJson.interface, wallet);
}

async function upgradeUpgradable(
    hre,
    proxyAddress,
    wallet,
    contractJson,
    implementationConstructorArgs = [],
    setupParams = '0x',
    env = 'testnet',
    chain = 'ethereum',
    shouldVerifyContract = false,
) {
    const proxy = new hre.ethers.Contract(proxyAddress, IUpgradable.abi, wallet);

    const implementationFactory = new hre.ethers.ContractFactory(contractJson.abi, contractJson.bytecode, wallet);

    const implementation = await implementationFactory.deploy(...implementationConstructorArgs);
    await implementation.deployed();

    const implementationCode = await wallet.provider.getCode(implementation.address);
    const implementationCodeHash = hre.ethers.utils.keccak256(implementationCode);

    const tx = await proxy.upgrade(implementation.address, implementationCodeHash, setupParams);
    await tx.wait();

    return tx;
}

module.exports = {
    deployCreate3Upgradable,
    deployCreate3InitUpgradable,
    upgradeUpgradable,
};
