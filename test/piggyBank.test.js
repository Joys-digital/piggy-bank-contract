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

    it('check constructor', async function() {
        assert.equal(await this.testInstance.basePlatform(), this.mlmPlatform.address);
    });

  describe('receive', function () {
    it('receive positive', async function() {
        assert.equal(await this.testInstance.totalAccrual(), 0);
        assert.equal(await this.testInstance.totalBalance(), 0);
        assert.deepEqual(
            await this.testInstance.user(user1),
            [
                false,
                false,
                '0',
                '0'
            ]
        );

         await this.testInstance.setVerificationStatus(user1, true);
         await this.testInstance.setVerificationStatus(user2, true);

        let result = await this.testInstance.send("1000");

        assert.equal(await this.testInstance.totalAccrual(), "500");
        assert.equal(await this.testInstance.totalBalance(), "1000");

        assert.equal(await this.testInstance.balanceOf(user1), "500");
        assert.equal(await this.testInstance.expectedRewardOf(user1), "500");
        assert.equal(await this.testInstance.clearBalanceOf(user1), "0");
        assert.equal(await this.testInstance.balanceOf(user2), "500");
        assert.equal(await this.testInstance.expectedRewardOf(user2), "500");
        assert.equal(await this.testInstance.clearBalanceOf(user2), "0");
        assert.deepEqual(
            await this.testInstance.user(user1),
            [
                true,
                false,
                '0',
                '0'
            ]
        );

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

  describe('changeBasePlatform', function () {
    it('changeBasePlatform positive', async function() {
        assert.equal((await this.testInstance.basePlatform()), this.mlmPlatform.address);

        const address = "0x0000000000000000000000000000000000000001";

        let result = await this.testInstance.changeBasePlatform(address);

        assert.equal((await this.testInstance.basePlatform()), address);

        await expectEvent(result, "ChangeBasePlatform", {
            newBasePlatform: address,
            oldBasePlatform: this.mlmPlatform.address
        })
    });

    it('changeBasePlatform negative', async function() {
        const address = "0x0000000000000000000000000000000000000001";

        await expectRevert(
            this.testInstance.changeBasePlatform(address, {from: accounts[1]}),
            "Ownable: caller is not the owner."
        );
    });
  });

  describe('withdraw', function () {
    it('withdraw after receive', async function() {
        await this.testInstance.setVerificationStatus(user1, true);
        await this.testInstance.setVerificationStatus(user2, true);

        await this.testInstance.send("1000");

        let balance1 = await web3.eth.getBalance(user1);
        let result1 = await this.testInstance.withdraw(user1, "500");

        assert.equal(
            await web3.eth.getBalance(user1),
            (new BN(balance1)).add(new BN("500")).toString()
        );

        await expectEvent(result1, "Withdraw", {
            from: user1,
            value: "500"
        });

    });
  });

  
});
