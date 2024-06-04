'use strict';

// const { Contract, ContractFactory } = require('ethers');
// const { getSaltFromKey } = require('./utils');

const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/interfaces/IDeployer.sol/IDeployer.json');
const chains = require('../chains.json');

const estimateGasForCreate3Deploy = async (hre, deployer, contractJson, args = []) => {
    const salt = getSaltFromKey(hre, '');
    const factory = new hre.ethers.ContractFactory(contractJson.abi, contractJson.bytecode);
    const bytecode = factory.getDeployTransaction(...args).data;
    return await deployer.estimateGas.deploy(bytecode, salt);
};

const estimateGasForCreate3DeployAndInit = async (hre, deployer, wallet, contractJson, args = [], initArgs = []) => {
    const salt = getSaltFromKey(hre, '');
    const factory = new hre.ethers.ContractFactory(contractJson.abi, contractJson.bytecode);
    const bytecode = factory.getDeployTransaction(...args).data;

    const address = await deployer.deployedAddress('0x', wallet.address, salt);
    const contract = new hre.ethers.Contract(address, contractJson.abi, wallet);
    const initData = (await contract.populateTransaction.init(...initArgs)).data;
    return await deployer.estimateGas.deployAndInit(bytecode, salt, initData);
};

const create3DeployContract = async (
    hre,
    deployerAddress,
    wallet,
    contractJson,
    key,
    args = [],
    txOptions = null,
    confirmations = null,
) => {
    if (txOptions && !Number.isNaN(Number(txOptions))) {
        txOptions = {
            gasLimit: txOptions,
        };
    }

    const deployer = new hre.ethers.Contract(deployerAddress, Create3Deployer.abi, wallet);
    const salt = getSaltFromKey(hre, key);
    const factory = new ContractFactory(contractJson.abi, contractJson.bytecode);
    const bytecode = factory.getDeployTransaction(...args).data;

    const tx = await deployer.deploy(bytecode, salt, txOptions);
    await tx.wait(confirmations);

    const address = await deployer.deployedAddress('0x', wallet.address, salt);

    return new Contract(address, contractJson.abi, wallet);
};

const create3DeployAndInitContract = async (
    hre,
    deployerAddress,
    wallet,
    contractJson, //proxyJson
    salt,
    args = [],
    initArgs = [],
    txOptions = null,
    confirmations = null,
) => {
    if (txOptions && !Number.isNaN(Number(txOptions))) {
        txOptions = {
            gasLimit: hre.ethers.utils.hexlify(5000000), // Manually set gas limit
        };
    }
    const deployer = new hre.ethers.Contract(deployerAddress, Create3Deployer.abi, wallet);
    // console.log(contractJson)
    const factory = new hre.ethers.ContractFactory(contractJson.abi, contractJson.bytecode);
    const bytecode = factory.getDeployTransaction(...args).data;
    const address = await deployer.deployedAddress('0x', wallet.address, salt);
    const contract = new hre.ethers.Contract(address, contractJson.abi, wallet);
    // const initData = (await contract.populateTransaction.init(...initArgs)).data;
    // const tx = await deployer.deployAndInit(bytecode, salt, initData, txOptions);
    const tx = await deployer.deploy(bytecode, salt, txOptions);
    // await contract.init()
    // contract.init()


    // await contract.init(chains[1].its, '0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE', chains[1].gateway, txOptions);
    // await contract.init();
    // console.log(await contract.s_its(), "IAM WORKING!!!!")

    // const tx2 = await address.init([chains[1].its, '0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE', chains[1].gateway]);
    // const receipt2 = await tx2.wait(confirmations)
    // console.log(receipt2, 'the receipt 2')

    return contract;
};

const getCreate3Address = async (hre, deployerAddress, wallet, salt) => {
    const deployer = new hre.ethers.Contract(deployerAddress, Create3Deployer.abi, wallet);
    // const salt = getSaltFromKey(hre, key);

    return await deployer.deployedAddress('0x', wallet.address, salt);
};

module.exports = {
    estimateGasForCreate3Deploy,
    estimateGasForCreate3DeployAndInit,
    create3DeployContract,
    create3DeployAndInitContract,
    getCreate3Address,
};
