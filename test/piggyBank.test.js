const { BN, constants, expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const PiggyBank = artifacts.require('PiggyBank');
const Vault = artifacts.require('Vault');
const MLMMock = artifacts.require('MLMMock');

contract('PiggyBank', function(accounts) {

  const [admin, user1, user2] = accounts;

  beforeEach('creating', async function () {
    this.testInstance = await PiggyBank.new();
    this.mlmPlatform = await MLMMock.new(this.testInstance.address);
    await this.testInstance.initialize(this.mlmPlatform.address);
    this.vault = await Vault.at(await this.testInstance.vault());
  });

  describe('receive', function () {
    it('receive positive', async function() {
        assert.equal(await this.testInstance.totalAccrual(), 0);
        assert.equal(await this.testInstance.totalBalance(), 0);

         await this.testInstance.setVerificationStatus(user1, true);
         await this.testInstance.setVerificationStatus(user2, true);

        let result = await this.testInstance.send("1000");

        assert.equal(await this.testInstance.totalAccrual(), "500");
        assert.equal(await this.testInstance.totalBalance(), "1000");

        await expectEvent(result, "Receive", {
            from: admin,
            value: "1000"
        });
    });
    it('receive negative', async function() {
        await expectRevert(
            this.testInstance.send("1000"),
            "PiggyBank: no verified-free partners."
        );
    });
  });

  describe('setVerificationStatus', function () {
    it('setVerificationStatus positive', async function() {
        assert.equal(await this.testInstance.isVerified(user1), false);
        assert.equal(await this.testInstance.totalVerifiedFree(), 0);

        let result = await this.testInstance.setVerificationStatus(user1, true);

        assert.equal(await this.testInstance.isVerified(user1), true);
        assert.equal(await this.testInstance.totalVerifiedFree(), 1);

        await expectEvent(result, "SetVerificationStatus", {
            owner: admin,
            target: user1,
            status: true
        });
    });
    it('setVerificationStatus negative', async function() {
        await expectRevert(
            this.testInstance.setVerificationStatus(user1, true, {from: accounts[1]}),
            "Ownable: caller is not the owner."
        );
    });
  });

  describe('hookPrimeReward', function () {
    beforeEach('creating', async function () {
        await this.vault.send(web3.utils.toWei("1", "ether"));
    });
    it('hookPrimeReward positive', async function() {

        assert.equal(await this.testInstance.isPrimeRewarded(user1), false);
        assert.equal(await this.testInstance.totalAccrual(), "0");
        assert.equal(await this.testInstance.totalBalance(), "0");
        assert.equal(await web3.eth.getBalance(this.vault.address), web3.utils.toWei("1", "ether"));
        
        await this.testInstance.setVerificationStatus(user1, true);
        let result = await this.mlmPlatform.primeHook(user1);

        assert.equal(await this.testInstance.isPrimeRewarded(user1), true);
        assert.equal(await this.testInstance.totalAccrual(), "0");
        assert.equal(await this.testInstance.totalBalance(), web3.utils.toWei("1", "ether"));
        assert.equal(await this.testInstance.balanceOf(user1), web3.utils.toWei("1", "ether"));
        assert.equal(await this.testInstance.clearBalanceOf(user1), web3.utils.toWei("1", "ether"));
        assert.equal(await web3.eth.getBalance(this.vault.address), "0");

        // TODO check event handling
        // await expectEvent(result, "HookPrimeReward", {
        //     from: this.mlmPlatform.address,
        //     target: user1,
        //     value: "100"
        // });
    });
    it('hookPrimeReward negative', async function() {
        await expectRevert(
            this.testInstance.setVerificationStatus(user1, true, {from: accounts[1]}),
            "Ownable: caller is not the owner."
        );
    });
  });

//   describe('changePiggyBank', function () {
//     it('positive', async function() {
//         assert.equal((await this.testInstance.piggyBank()), ZERO_ADDRESS);

//         const address = "0x0000000000000000000000000000000000000001";

//         let result = await this.testInstance.changePiggyBank(address);

//         assert.equal((await this.testInstance.piggyBank()), address);

//         await expectEvent(result, "ChangePiggyBank", {
//             newPiggyBankContract: address,
//             oldPiggyBankContract: ZERO_ADDRESS
//         })
//     });

//     it('negative', async function() {
//         const address = "0x0000000000000000000000000000000000000001";

//         await expectRevert(
//             this.testInstance.changePiggyBank(address, {from: accounts[1]}),
//             "Ownable: caller is not the owner."
//         );
//     });
//   });

  
});
