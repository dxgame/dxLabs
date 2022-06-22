const { expect } = require("chai");
const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

const prepare = async function (contractName, libraries, ...args) {
  const signers = await ethers.getSigners();
  const Contract = await ethers.getContractFactory(contractName, { libraries });
  const contract = await Contract.deploy(...args);

  await contract.deployed();
  return [contract, ...signers];
};

const tx = async function (_tx) {
  return (await _tx).wait();
};

const { HashZero, AddressZero } = ethers.constants;
const nobody = { address: AddressZero };

const StateLib = {
  getHash: (prevHash, signer, message) => {
    return ethers.utils.solidityKeccak256(
      ["bytes32", "address", "string"],
      [prevHash, signer.address, message]
    );
  },

  getParams: async function ({ prevHash = HashZero, signer, message = "" }) {
    const stateHash = StateLib.getHash(prevHash, signer, message);
    const flatSig = await signer.signMessage(ethers.utils.arrayify(stateHash));
    const sig = ethers.utils.splitSignature(flatSig);
    return [prevHash, signer.address, message, sig.v, sig.r, sig.s];
  },
};

async function getUpdateStateEventArgs(contract, player, nextPlayer, step) {
  const preBlock = await ethers.provider.getBlock("latest");
  const game = await contract.game();
  const MAX_BLOCKS_PER_MOVE = game.MAX_BLOCKS_PER_MOVE.toNumber();

  return [
    game.id,
    game.round,
    step,
    player.address,
    nextPlayer.address,
    preBlock.number + 1 + MAX_BLOCKS_PER_MOVE,
    preBlock.number + 1 + MAX_BLOCKS_PER_MOVE * 2,
  ];
}

async function expectPlayers(contract, defender, challenger) {
  expect(await contract.defender()).to.equal(defender.address);
  expect(await contract.challenger()).to.equal(challenger.address);
}

async function expectNoPlayers(contract) {
  expect(await contract.defender()).to.equal(AddressZero);
  expect(await contract.challenger()).to.equal(AddressZero);
}

async function init(contract, defender) {
  await expectNoPlayers(contract);

  await tx(
    contract
      .connect(defender)
      .challenge(...(await StateLib.getParams({ signer: defender })))
  );
}

async function challenge(contract, challenger, defender) {
  await tx(
    contract
      .connect(challenger)
      .challenge(...(await StateLib.getParams({ signer: challenger })))
  );

  await expectPlayers(contract, defender, challenger);
}

async function defend(contract, defender, challenger) {
  await expect(
    contract.connect(defender).defend(
      ...(await StateLib.getParams({
        prevHash: await contract.lastStateHash(),
        signer: defender,
      }))
    )
  )
    .to.emit(contract, "UpdateStateEvent")
    .withArgs(
      ...(await getUpdateStateEventArgs(contract, defender, challenger, 2))
    );
}

module.exports = {
  N,
  prepare,
  tx,
  StateLib,

  nobody,
  expectPlayers,
  expectNoPlayers,

  init,
  challenge,
  defend,
};
