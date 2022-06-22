const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
  N,
  prepare,
  tx,
  StateLib,
  nobody,
  expectPlayers,
  init,
  challenge,
  defend,
} = require("./utils");

describe("GuessWhat", function () {
  // eslint-disable-next-line no-unused-vars
  let gameLib, contract, deployer, defender, challenger, bystander;

  beforeEach(async function () {
    [gameLib] = await prepare("GameLib");
    const libraries = { GameLib: gameLib.address };
    [contract, deployer, defender, challenger, bystander] = await prepare(
      "GuessWhat",
      libraries,
      N`10`
    );
  });

  it("Should update defender with a new challenge if there's no defender", async function () {
    await init(contract, defender);
    await expectPlayers(contract, defender, nobody);
  });

  it("Should update challenger with a new challenge if there is defender", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, defender);
    await expectPlayers(contract, defender, challenger);
  });

  it("Should not allowed to challenge with a challenge in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, defender);
    await expectPlayers(contract, defender, challenger);

    await expect(
      contract
        .connect(bystander)
        .challenge(...(await StateLib.getParams({ signer: bystander })))
    ).to.be.revertedWith("GuessWhat: move not allowed");
  });

  it("Should be able to defend with a challenge in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, defender);
    await defend(contract, defender, challenger);
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await expect(
      contract
        .connect(defender)
        .defend(...(await StateLib.getParams({ signer: defender })))
    ).to.be.revertedWith("GuessWhat: move not allowed");

    await tx(
      contract
        .connect(defender)
        .challenge(...(await StateLib.getParams({ signer: defender })))
    );
    await expect(
      contract
        .connect(defender)
        .defend(...(await StateLib.getParams({ signer: defender })))
    ).to.be.revertedWith("GuessWhat: move not allowed");

    await tx(
      contract
        .connect(challenger)
        .challenge(...(await StateLib.getParams({ signer: challenger })))
    );
    await expect(
      contract
        .connect(bystander)
        .defend(...(await StateLib.getParams({ signer: bystander })))
    ).to.be.revertedWith("GuessWhat: not for you now");
  });

  it("Should be able to reveal challenge with defend in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, defender);
    await defend(contract, defender, challenger);
  });

  // TODO: reveal challenge
});
