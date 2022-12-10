
/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require("dotenv").config()
require("@nomiclabs/hardhat-ethers")
require("hardhat-deploy")

const key = ''

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.8.6',
  settings: {
    optimizer: {
      enabled: true,
      runs: 1000000
    }
  }, 
  mocha: {
    timeout: 90000
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      blockGasLimit: 18800000,
    },
    local_ganache: {
      url: `HTTP://127.0.0.1:7545`,
      accounts: [`0x260d12c5b92e837709d94972ebc42b89c74fae72affbdd2090be0caf51eac55b`],
    },
    polygon_mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`0x` + process.env.PRIVATE_KEY]
    },
    polygon_mumbai_infura: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x` + process.env.PRIVATE_KEY]
    },
    polygon_mumbai_matic_vigil: {
      url: `https://rpc-mainnet.maticvigil.com/v1/${process.env.MATIC_VIGIL_API_KEY}`,
      accounts: [`0x` + process.env.PRIVATE_KEY]
    },
  },
  namedAccounts: {
    deployer: 0
  },
}
