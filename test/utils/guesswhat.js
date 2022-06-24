const { expect } = require("chai");
const { ethers } = require("hardhat");
// eslint-disable-next-line no-unused-vars
const { tx, x, HashZero, nobody } = require("./common");

const wrong = {
  you: "GuessWhat: not for you now",
  move: "GuessWhat: move not allowed",
  notWinner: "GuessWhat: you not winner",
};

const msg = {
  challenge: "GuessWhat: challenge you",
  defend: "GuessWhat: defend you",
};

const StateLib = {
  getHash: (prevHash, signer, message) => {
    return ethers.utils.solidityKeccak256(
      ["bytes32", "address", "string"],
      [prevHash, signer.address, message]
    );
  },

  getParams: async function ({ prevHash = HashZero, player, message = "" }) {
    const stateHash = StateLib.getHash(prevHash, player, message);
    const flatSig = await player.signMessage(ethers.utils.arrayify(stateHash));
    const sig = ethers.utils.splitSignature(flatSig);
    return [prevHash, player.address, message, sig.v, sig.r, sig.s];
  },
};

async function getUpdateStateEventArgs(contract, player, step) {
  const preBlock = await ethers.provider.getBlock("latest");
  const game = await contract.game();
  const MAX_BLOCKS_PER_MOVE = game.MAX_BLOCKS_PER_MOVE.toNumber();
  const otherPlayer = await contract.opponent(player.address);

  const updateStateEvent = [
    game.id,
    game.round,
    step,
    player.address,
    otherPlayer,
    preBlock.number + 1 + MAX_BLOCKS_PER_MOVE,
  ];

  return updateStateEvent;
}

async function getStartEventArgs(contract, player) {
  const game = await contract.game();
  return [game.id, game.round + 1, player.address, await contract.defender()];
}

async function getWinningEventArgs(contract, winner) {
  const game = await contract.game();
  return [game.id, game.round, winner.address];
}

async function expectPlayers(contract, defender, challenger) {
  expect(await contract.defender()).to.equal(defender.address);
  expect(await contract.challenger()).to.equal(challenger.address);
}

async function expectNoPlayers(contract) {
  expect(await contract.defender()).to.equal(nobody.address);
  expect(await contract.challenger()).to.equal(nobody.address);
}

async function move(contract, player, action, args = {}) {
  const prevHash = args.prevHash || (await contract.lastStateHash());
  const params = await StateLib.getParams({ player, prevHash, ...args });

  return contract.connect(player)[action](...params);
}

async function init(contract, firstcomer) {
  await expectNoPlayers(contract);
  await expect(move(contract, firstcomer, "challenge"))
    .to.emit(contract, "WinningEvent")
    .withArgs(...(await getWinningEventArgs(contract, firstcomer)));
}

function moveNotAllowed(contract, player, action, error = wrong.move) {
  return expect(move(contract, player, action)).to.be.revertedWith(error);
}

async function challenge(contract, challenger, message = x(msg.challenge)) {
  await expect(move(contract, challenger, "challenge", { message }))
    .to.emit(contract, "StartEvent")
    .withArgs(...(await getStartEventArgs(contract, challenger)));
}

async function defend(contract, defender, message = x(msg.defend)) {
  await expect(move(contract, defender, "defend", { message }))
    .to.emit(contract, "UpdateStateEvent")
    .withArgs(...(await getUpdateStateEventArgs(contract, defender, 2)));
}

async function revealChallenge(contract, challenger, message = msg.challenge) {
  await expect(move(contract, challenger, "revealChallenge", { message }))
    .to.emit(contract, "UpdateStateEvent")
    .withArgs(...(await getUpdateStateEventArgs(contract, challenger, 3)));
}

async function revealDefend(contract, defender, message = msg.defend) {
  await expect(move(contract, defender, "revealDefend", { message }))
    .to.emit(contract, "UpdateStateEvent")
    .withArgs(...(await getUpdateStateEventArgs(contract, defender, 4)));
}

async function claimWinning(contract, winner) {
  await expect(move(contract, winner, "claimWinning"))
    .to.emit(contract, "WinningEvent")
    .withArgs(...(await getWinningEventArgs(contract, winner)));
}

async function expectWinner(contract, winner) {
  await expect(await contract.whoWins()).to.equal(winner.address);
}

async function cannotClaimWinning(contract, player) {
  return moveNotAllowed(contract, player, "claimWinning", wrong.notWinner);
}

module.exports = {
  wrong,
  StateLib,
  expectPlayers,
  expectNoPlayers,

  init,
  move,
  moveNotAllowed,
  challenge,
  defend,
  revealChallenge,
  revealDefend,
  claimWinning,
  cannotClaimWinning,
  expectWinner,
};
