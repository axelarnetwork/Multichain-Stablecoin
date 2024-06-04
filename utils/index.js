const { HardhatRuntimeEnvironment } = require('hardhat/types');

const getWallet = (rpc, hre) => {
    const key = process.env.PRIVATE_KEY;
    if (!key) {
        throw new Error('invalid key');
    }

    const provider = hre.ethers.getDefaultProvider(rpc);
    const wallet = new hre.ethers.Wallet(key, provider);
    const connectedWallet = wallet.connect(provider);

    return connectedWallet;
};
module.exports = {
    getWallet
}