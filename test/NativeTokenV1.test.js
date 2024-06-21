const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');
const { createNetwork, relay, deployContract } = require('@axelar-network/axelar-local-dev');
const { create3DeployContract } = require('@axelar-network/axelar-gmp-sdk-solidity/scripts/create3Deployer');

const Proxy = require('@openzeppelin/contracts/build/contracts/TransparentUpgradeableProxy.json');
const ProxyAdmin = require('@openzeppelin/contracts/build/contracts/ProxyAdmin.json');
const Deployer = require('../artifacts/contracts/Deployer.sol/Deployer.json');
const AccessControl = require('../artifacts/contracts/AccessControl.sol/AccessControl.json');
const Factory = require('../artifacts/contracts/TokenFactory.sol/TokenFactory.json');
const NativeTokenV1 = require('../artifacts/contracts/NativeTokenV1.sol/NativeTokenV1.json');
const NativeTokenV2 = require('../artifacts/contracts/NativeTokenV2.sol/NativeTokenV2.json');

describe('NativeTokenV1', () => {
    let polygon;
    let avalanche;
    let accessControlProxy;
    let tokenV1Proxy;
    let owner;
    let notOwner;
    let senderPolygon;
    let receiverPolygon;
    let receiverAvalanche;

    const burnRate = 10000;
    const txFeeRate = 20000;

    before(async () => {
        // Initialize a Polygon network
        polygon = await createNetwork({
            name: 'Polygon',
            port: 1545,
        });

        // Initialize an Avalanche network
        avalanche = await createNetwork({
            name: 'Avalanche',
            port: 1546,
        });
        [senderPolygon, receiverPolygon] = polygon.userWallets;
        [receiverAvalanche] = avalanche.userWallets;
    });

    beforeEach(async () => {
        const proxyAdmin = await deployContract(senderPolygon, ProxyAdmin, [senderPolygon.address]);

        //ACCESS
        const implAccessControl = await deployContract(senderPolygon, AccessControl, []);
        const proxyAccess = await deployContract(senderPolygon, Proxy, [implAccessControl.address, proxyAdmin.address, '0x']);

        const accessControlFactory = await ethers.getContractFactory('AccessControl');
        accessControlProxy = accessControlFactory.attach(proxyAccess.address);

        await accessControlProxy.initialize(senderPolygon.address);

        //TOKEN
        const implTokenV1 = await deployContract(senderPolygon, NativeTokenV1, []);
        const proxyTokenV1 = await deployContract(senderPolygon, Proxy, [implTokenV1.address, proxyAdmin.address, '0x']);

        const proxyTokenFactory = await ethers.getContractFactory('NativeTokenV1');
        tokenV1Proxy = proxyTokenFactory.attach(proxyTokenV1.address);

        const onePercent = 10000;
        const threePercent = 30000;

        await tokenV1Proxy.initialize(accessControlProxy.address, polygon.interchainTokenService.address, onePercent, threePercent);

        await tokenV1Proxy.s_test()
  
    });
    describe('initialize', async () => {
        it('should revert if initialize called twice', async () => {
            console.log('test me');
            // expect(await implTokenV1.initialize(accessControlProxy.address, polygon.interchainTokenService.address, onePercent, threePercent)).to.be.reverted
        });
    });
    /*
    describe('Deployment', () => {
        it('Should set the right owner', async () => {
            expect(await accessControlProxy.isAdmin(await owner.getAddress())).to.be.true;
        });

        it('Should have the correct initial settings', async () => {
            expect(await token.s_accessControl()).to.equal(accessControlProxy.target);
            expect(await token.s_burnRate()).to.equal(burnRate);
            expect(await token.s_txFeeRate()).to.equal(txFeeRate);
            expect(await token.name()).to.equal('Interchain Token');
            expect(await token.symbol()).to.equal('ITS');
        });
    });

    describe('Admin Functionality', () => {
        it('should pause contract', async () => {
            expect(await token.paused()).to.be.false;
            await token.pause();
            expect(await token.paused()).to.be.true;
        });

        it('should unpause contract', async () => {
            await token.pause();
            expect(await token.paused()).to.be.true;
            await token.unpause();
            expect(await token.paused()).to.be.false;
        });

        it('should set new burn rate', async () => {
            const burnRateBefore = await token.s_burnRate();
            expect(await token.s_burnRate()).to.equal(burnRateBefore);
            await token.setBurnRate(123);
            expect(await token.s_burnRate()).to.equal(BigInt(123));
        });

        it('should set new tx fee rate', async () => {
            const txFeeRateBefore = await token.s_txFeeRate();
            expect(await token.s_txFeeRate()).to.equal(txFeeRateBefore);
            await token.setTxFee(123);
            expect(await token.s_txFeeRate()).to.equal(BigInt(123));
        });
    });
    */
});
