
const{BN, expectRevert, expectEvent} = require("@openzeppelin/test-helpers");
const {expect} = require('chai');

const Rent = artifacts.require("Rent");
const FUSD = artifacts.require("FUSD");
const FAlchemistV2 = artifacts.require("FAlchemistV2");

contract("Rent.sol", (accounts) => {
  const root = accounts[0];
  const renter = accounts[1];
  const occupier = accounts[2];

  let rent;
  let fUSD;
  let vault;

  context("fonctions", function(){

    beforeEach(async () => {
      fUSD = await FUSD.new(100000, {from:root});
      fUSD.transfer(occupier, 10000, {from:root});
      fUSD.transfer(renter, 30000, {from:root});
      vault = await FAlchemistV2.new(fUSD.address, {from:root});
      rent = await Rent.new(vault.address, fUSD.address, renter, occupier, 400, {from:root});
    });

    it("... payTheRent testing function", async () => {
      await expectRevert(rent.payTheRent(400, {from:root}), "Rent: access not granted");
      await expectRevert(rent.payTheRent(400, {from:occupier}), "Rent: the rent is not correct");
    });

    it("... first turn rental testing scenario", async () => {
      await fUSD.approve(vault.address, 800, {from:occupier});
      await rent.payTheRent(800, {from:occupier});
      await fUSD.approve(rent.address, 400,{from:occupier});
      await rent.claim_rent({from:renter});
      balance = await fUSD.balanceOf(renter);
      expect(balance.words[0]).to.equal(30400);
    });

    it("... getNextPaiement testing function", async () => {
      await rent.getNextPaiement({from:root});
      var _thresholdBN = await rent.threshold();
      var _threshold = _thresholdBN.words[0];
      expect(_threshold * 400 / 1000).to.equal(800);

      await fUSD.approve(vault.address, 800, {from:occupier});
      await rent.payTheRent(800, {from:occupier});
      await fUSD.approve(vault.address, 100);
      await vault.update(100);

      await fUSD.approve(rent.address, 400,{from:occupier});
      await rent.claim_rent({from:renter});

      await rent.getNextPaiement({from:root});
      _thresholdBN = await rent.threshold();
      _threshold = _thresholdBN.words[0];
      ts = await vault.totalSupply();
      expect(_threshold * 400/1000).to.equal(700);
    });

    it("... terminate testing function", async () => {
      await expectRevert(rent.terminate({from:root}), "Rent: access not granted");

      await fUSD.approve(vault.address, 800, {from:occupier});
      await rent.payTheRent(800, {from:occupier});
      await fUSD.approve(rent.address, 400,{from:occupier});
      await rent.claim_rent({from:renter});
      result = await rent.terminate({from:occupier});
      expectEvent(result, "WorkflowStatusChange", {previousStatus:new BN(0), newStatus:new BN(2)});
      balance = await fUSD.balanceOf(renter);
      expect(balance.words[0]).to.equal(30400);
      balance = await fUSD.balanceOf(occupier);
      expect(balance.words[0]).to.equal(9600);
    });

    it("... full rental testing scenario", async () => {
      await fUSD.approve(vault.address, 800, {from:occupier});
      await rent.payTheRent(800, {from:occupier});
      await fUSD.approve(rent.address, 400,{from:occupier});
      await rent.claim_rent({from:renter});
      await fUSD.approve(vault.address, 300);
      await vault.update(100);
      await rent.getNextPaiement({from:root});
      _thresholdBN = await rent.threshold();
      _threshold = _thresholdBN.words[0];
      ts = await vault.totalSupply();
      next_rent = _threshold * 400/1000;

      await fUSD.approve(vault.address, next_rent, {from:occupier});
      await rent.payTheRent(next_rent, {from:occupier});
      await fUSD.approve(rent.address, 400, {from:occupier});
      await rent.claim_rent({from:renter});
      await fUSD.approve(vault.address, 300);
      await vault.update(100);
      await rent.getNextPaiement({from:root});
      _thresholdBN = await rent.threshold();
      _threshold = _thresholdBN.words[0];
      ts = await vault.totalSupply();
      next_rent = _threshold * 400/1000;

      console.log(next_rent);

    });
  });
})



