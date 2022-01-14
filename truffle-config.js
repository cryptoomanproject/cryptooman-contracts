const HDWalletProvider = require("@truffle/hdwallet-provider");
const mnemonic = "";
const address = "";

module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    test: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    matic: {
      provider: new HDWalletProvider(
          mnemonic,
          'https://rpc-mainnet.maticvigil.com'
      ),
      from: address,
      gas: 7500000,
      gasPrice: 35000000000,
      network_id: 137,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    mumbai: {
      provider: () => new HDWalletProvider(
          mnemonic,
          'https://rpc-mumbai.maticvigil.com'
      ),
      from: address,
      network_id: 80001,
      gas: 7500000,
      gasPrice: 7500000000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    enableTimeouts: false,
    before_timeout: 200000,
    timeout: 200000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12",
      // version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        }
      //  evmVersion: "byzantium"
      }
    }
  }
  
};
