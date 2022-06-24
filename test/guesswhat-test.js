const prepare = require("./utils/prepare");
const { N, nobody, x, mineBlocks } = require("./utils/common");
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
  cannotClaimWinning,
  expectWinner,
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
    await moveNotAllowed(contract, bystander, "challenge", wrong.playing);
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

  it("Should be able to claim winning if defender wins", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await defend(contract, defender, x`1`);
    await revealChallenge(contract, challenger, "1");
    await revealDefend(contract, defender, "1");

    await expectWinner(contract, defender);
    await claimWinning(contract, defender);
    await expectPlayers(contract, defender, nobody);
  });

  it("Should be able to claim winning if challenger wins", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await defend(contract, defender, x`0`);
    await revealChallenge(contract, challenger, "1");
    await revealDefend(contract, defender, "0");

    await expectWinner(contract, challenger);
    await claimWinning(contract, challenger);
    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if defender did not response #1 defend", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, challenger);
    await mineBlocks(150);
    await claimWinning(contract, challenger);

    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if defender did not response #1 reveal", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await defend(contract, defender, x`1`);
    await revealChallenge(contract, challenger, "1");
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, challenger);
    await mineBlocks(150);
    await claimWinning(contract, challenger);

    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if challenger did not response #2 reveal", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await defend(contract, defender, x`1`);
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, defender);
    await mineBlocks(150);
    await claimWinning(contract, defender);

    await expectPlayers(contract, defender, nobody);
  });

  it("Should be able to start a new game after last game settled", async function () {
    await init(contract, defender);
    await challenge(contract, challenger, x`1`);
    await defend(contract, defender, x`0`);
    await revealChallenge(contract, challenger, "1");
    await revealDefend(contract, defender, "0");

    await challenge(contract, bystander);
    await expectPlayers(contract, challenger, bystander);
  });

  // Once win, the winner is the winner

  // TODO: Keep the winner the winner if all states recorded
  // Challenger first, Winner first.
  // Who left the game, who forever lost

  // TODO: forwarders
  // TODO: MAX_STATES == 0, infinite game, customized game ending indicator
});
