require("dotenv").config();

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      from: process.env.BNB_TESTNET_ACCOUNT,
      accounts: {
        mnemonic: process.env.BNB_TESTNET_MNEMONIC
      }
    }
  },
  etherscan: {
    apiKey: process.env.SCANNER_API_KEY
  }
};

export default config;
