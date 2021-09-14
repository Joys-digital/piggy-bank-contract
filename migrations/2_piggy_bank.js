const PiggyBank = artifacts.require("PiggyBank");

const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function(deployer, network, accounts) {
  let newBasePlatform = "0x80e1a76050123ec70c716f96a3a54ea00635acd2";

  if (network == "test") {
    //
  } else {
    const instance = await deployProxy(PiggyBank, [newBasePlatform], { deployer });
    console.log('Deployed', instance.address);
  }
};