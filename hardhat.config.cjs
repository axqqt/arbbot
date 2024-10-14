require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.4',
  networks: {
    hardhat: {
      forking: {
        url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      },
    },
    // Add other networks as needed
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};