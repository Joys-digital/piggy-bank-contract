const Vault = artifacts.require("Vault");
const PiggyBank = artifacts.require("PiggyBank");

module.exports = async function(deployer, network, accounts) {
  let newBasePlatform;

  if (network == "toys") {
    newBasePlatform = accounts[1];
  } else
  if (network == "joysPoas") {
    newBasePlatform = accounts[1];
  } else {
    newBasePlatform = accounts[1];
  }
  
  await deployer.deploy(Vault);
  const vaultAddress = (await Vault.deployed()).address;

  await deployer.deploy(PiggyBank, newBasePlatform, vaultAddress);
  let piggyBankAddress = (await PiggyBank.deployed()).address;

  await (await Vault.at(vaultAddress)).transferOwnership(piggyBankAddress);

};