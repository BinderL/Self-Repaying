const FUSD = artifacts.require("FUSD");
const Vault = artifacts.require("FAlchemistV2");
const Rent = artifacts.require("Rent");

module.exports = async function(deployer, network, account) {
  const root = account[0];
  const renter = account[1];
  const occupier = account[2];
  await deployer.deploy(FUSD, 100000);
  const _fUSD = await FUSD.deployed();
  await _fUSD.transfer(renter, 30000);
  await _fUSD.transfer(occupier, 10000)
  await deployer.deploy(Vault, _fUSD.address);
  const _vault = await Vault.deployed();
  await deployer.deploy(Rent, _vault.address, _fUSD.address, renter, occupier, 400);

};
