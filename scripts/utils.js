// const { ethers } = require('hardhat');
const { deployContract } = require('./deploy');
// const { AddressZero } = ethers.constants;
// const { defaultAbiCoder, keccak256 } = ethers.utils;

function getRandomBytes32(hre) {
    return hre.ethers.keccak256(defaultAbiCoder.encode(['uint256'], [Math.floor(new Date().getTime() * Math.random())]));
}

async function approveContractCall(
    gateway,
    sourceChain,
    sourceAddress,
    contractAddress,
    payload,
    sourceTxHash = getRandomBytes32(),
    sourceEventIndex = 0,
    commandId = getRandomBytes32(),
) {
    const params = defaultAbiCoder.encode(
        ['string', 'string', 'address', 'bytes32', 'bytes32', 'uint256'],
        [sourceChain, sourceAddress, contractAddress, keccak256(payload), sourceTxHash, sourceEventIndex],
    );
    await gateway.approveContractCall(params, commandId).then((tx) => tx.wait);

    return commandId;
}

async function approveContractCallWithMint(
    gateway,
    sourceChain,
    sourceAddress,
    contractAddress,
    payload,
    symbol,
    amount,
    sourceTxHash = getRandomBytes32(),
    sourceEventIndex = 0,
    commandId = getRandomBytes32(),
) {
    const params = defaultAbiCoder.encode(
        ['string', 'string', 'address', 'bytes32', 'string', 'uint256', 'bytes32', 'uint256'],
        [sourceChain, sourceAddress, contractAddress, keccak256(payload), symbol, amount, sourceTxHash, sourceEventIndex],
    );
    await gateway.approveContractCallWithMint(params, commandId).then((tx) => tx.wait);

    return commandId;
}

async function deployGatewayToken(gateway, tokenName, tokenSymbol, tokenDecimals, walletForExternal) {
    let tokenAddress = AddressZero;

    if (walletForExternal) {
        const token = await deployContract(walletForExternal, 'GatewayToken', [tokenName, tokenSymbol, tokenDecimals]);
        tokenAddress = token.address;
    }

    const params = defaultAbiCoder.encode(
        ['string', 'string', 'uint8', 'uint256', 'address', 'uint256'],
        [tokenName, tokenSymbol, tokenDecimals, 0, tokenAddress, 0],
    );
    const commandId = getRandomBytes32();
    await gateway.deployToken(params, commandId).then((tx) => tx.wait);
}

module.exports = {
    getRandomBytes32,
    approveContractCall,
    approveContractCallWithMint,
    deployGatewayToken,
};
