const { expect } = require("chai");
const { ethers } = require("hardhat");
// eslint-disable-next-line no-unused-vars
const { tx, x, HashZero, messHexStr, nobody } = require("./common");

const wrong = {
  noGame: "DxGame: game not started",
  you: "DxGame: not for you now",
  late: "DxGame: you are too late",
  move: "DxGame: move not allowed",
  match: "GuessBit: do not match",
  winning: "DxGame: nobody winning",
  playing: "DxGame: somebody playing",
  signature: "DxGame: signature not right",
};

const msg = {
  challenge: "DxGame: challenge you",
  defend: "DxGame: defend you",
};

const StateManager = {
  getHash: (prevHash, signer, message) => {
    return ethers.utils.solidityKeccak256(
      ["bytes32", "address", "string"],
      [prevHash, signer.address, message]
    );
  },

  getParams: async function ({ prevHash = HashZero, player, message = "" }) {
    const stateHash = StateManager.getHash(prevHash, player, message);
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

async function getStartEventArgs(contract, player, defender) {
  const game = await contract.game();
  return [game.id, game.round.add(1), player.address, defender.address];
}

async function getWinningEventArgs(contract, winner, announcer = winner) {
  const game = await contract.game();
  return [game.id, game.round, winner.address, announcer.address];
}

async function expectPlayers(contract, defender, challenger) {
  expect(await contract.defender()).to.equal(defender.address);
  expect(await contract.challenger()).to.equal(challenger.address);
}

async function expectNoPlayers(contract) {
  expect(await contract.defender()).to.equal(nobody.address);
  expect(await contract.challenger()).to.equal(nobody.address);
}

async function move(contract, player, action, args = {}, processParams) {
  const prevHash = args.prevHash || (await contract.lastStateHash());
  let params = await StateManager.getParams({ player, prevHash, ...args });
  params = processParams ? processParams(params) : params;
  const forwarder = contract.__god_forbid__forwarder || player;
  return contract.connect(forwarder)[action](...params);
}

async function messSign(contract, player, action, args, messFn) {
  const [index, fn] = messFn;
  await expect(
    move(contract, player, action, args, (params) => {
      params[index] = fn(params[index]);
      return params;
    })
  ).to.be.revertedWith(wrong.signature);
}

async function messUpSigns(contract, player, action, args, messFns) {
  for (const messFn of messFns) {
    await messSign(contract, player, action, args, messFn);
  }
}

async function failMessSignsMove(contract, player, action, args) {
  await messUpSigns(contract, player, action, args, [
    [0, (prevHash) => messHexStr(prevHash)],
    [1, (address) => nobody.address],
    [2, (message) => message + "*"],
    [3, (v) => v + 1],
    [4, (r) => messHexStr(r)],
    [5, (s) => messHexStr(s)],
  ]);
}

async function init(contract, firstcomer, forwarder) {
  await expectNoPlayers(contract);

  if (forwarder) {
    contract.__god_forbid__forwarder = forwarder;
  }

  await expect(move(contract, firstcomer, "challenge"))
    .to.emit(contract, "WinningEvent")
    .withArgs(...(await getWinningEventArgs(contract, firstcomer)));
}

function moveNotAllowed(contract, player, action, error = wrong.move, args) {
  return expect(move(contract, player, action, args)).to.be.revertedWith(error);
}

async function challenge(
  contract,
  challenger,
  defender,
  message = x(msg.challenge)
) {
  await expect(move(contract, challenger, "challenge", { message }))
    .to.emit(contract, "StartEvent")
    .withArgs(...(await getStartEventArgs(contract, challenger, defender)));
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

async function claimWinning(contract, winner, announcer) {
  await expect(move(contract, announcer, "claimWinning"))
    .to.emit(contract, "WinningEvent")
    .withArgs(...(await getWinningEventArgs(contract, winner, announcer)));
}

async function fight(
  contract,
  { challenger, defender, forwarder },
  [challengeHash, defendHash, revealedChallenge, revealedDefend]
) {
  await init(contract, defender, forwarder);

  if (challengeHash) {
    await challenge(contract, challenger, defender, challengeHash);
    await expectPlayers(contract, defender, challenger);
  }

  if (defendHash) {
    await defend(contract, defender, defendHash);
  }

  if (revealedChallenge) {
    await revealChallenge(contract, challenger, revealedChallenge);
  }

  if (revealedDefend) {
    await revealDefend(contract, defender, revealedDefend);
  }
}

module.exports = {
  wrong,
  StateManager,
  expectPlayers,
  expectNoPlayers,

  fight,
  init,
  move,
  failMessSignsMove,
  moveNotAllowed,
  challenge,
  defend,
  revealChallenge,
  revealDefend,
  claimWinning,
};
