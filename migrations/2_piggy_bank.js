const Vault = artifacts.require("Vault");
const PiggyBank = artifacts.require("PiggyBank");

module.exports = async function(deployer, network, accounts) {
  let newBasePlatform;

  if (network == "test") {
    //
  } else {
    await deployer.deploy(PiggyBank, newBasePlatform);
  }
};