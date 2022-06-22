const prepare = require("./utils/prepare");
const { N, nobody } = require("./utils/common");
const {
  wrong,
  expectPlayers,
  expectNoPlayers,
  moveNotAllowed,

  init,
  challenge,
  defend,
  revealChallenge,
  revealDefend,
  claimWinning,
} = require("./utils/guesswhat");

describe("GuessWhat", function () {
  // eslint-disable-next-line no-unused-vars
  let contract, deployer, defender, challenger, bystander;

  beforeEach(async function () {
    const preparation = await prepare("GuessWhat", "GameLib", N`10`);
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
    await defend(contract, defender);
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    await expectNoPlayers(contract);
    await moveNotAllowed(contract, defender, "defend");

    await init(contract, defender);
    await moveNotAllowed(contract, defender, "defend");

    await challenge(contract, challenger);
    await moveNotAllowed(contract, bystander, "defend", wrong.you);
  });

  it("Should be able to reveal challenge with defend in effect", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await defend(contract, defender);
    await revealChallenge(contract, challenger);
  });

  it("Should be able to reveal defend with revealed challenge", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await defend(contract, defender);
    await revealChallenge(contract, challenger);
    await revealDefend(contract, defender);
  });

  it("Should be able to claim winning with revealed defend", async function () {
    await init(contract, defender);
    await challenge(contract, challenger);
    await defend(contract, defender);
    await revealChallenge(contract, challenger);
    await revealDefend(contract, defender);
    await claimWinning(contract, defender);
  });
});
