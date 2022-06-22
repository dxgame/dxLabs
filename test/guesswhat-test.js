const { expect } = require("chai");

const {
  N,
  prepare,
  tx,
  StateLib,
  nobody,
  init,
  expectPlayers,
  expectNoPlayers,
  moveNotAllowed,
  challenge,
  defend,
} = require("./utils");

describe("GuessWhat", function () {
  // eslint-disable-next-line no-unused-vars
  let gameLib, contract, deployer, defender, challenger, bystander;

  beforeEach(async function () {
    [gameLib] = await prepare("GameLib");
    const libraries = { GameLib: gameLib.address };
    const preparation = await prepare("GuessWhat", libraries, N`10`);
    [contract, deployer, defender, challenger, bystander] = preparation;
  });

  it("Should update defender with a new challenge if there's no defender", async function () {
    await init(contract, defender);
    await expectPlayers(contract, defender, nobody);
  });

  it("Should update challenger with a new challenge if there is defender", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await expectPlayers(contract, defender, challenger);
  });

  it("Should not allowed to challenge with a challenge in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await expectPlayers(contract, defender, challenger);
    await moveNotAllowed(contract, bystander, "challenge");
  });

  it("Should be able to defend with a challenge in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await defend(contract, defender, challenger);
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    await expectNoPlayers(contract);
    await moveNotAllowed(contract, defender, "defend");

    await init(contract, defender);
    await moveNotAllowed(contract, defender, "defend");

    await challenge(contract, challenger);

    await expect(
      contract
        .connect(bystander)
        .defend(...(await StateLib.getParams({ signer: bystander })))
    ).to.be.revertedWith("GuessWhat: not for you now");
  });

  it("Should be able to reveal challenge with defend in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await defend(contract, defender, challenger);
  });

  // TODO: reveal challenge
});
