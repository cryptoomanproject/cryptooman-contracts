const CrypTooman = artifacts.require("CrypTooman");

module.exports = function(deployer, network, accounts) {
  
  deployer.deploy(CrypTooman);
};
