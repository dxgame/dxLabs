const prepare = require("./utils/prepare");
const { N, nobody, x, mineBlocks } = require("./utils/common");
const {
  wrong,
  expectPlayers,
  expectNoPlayers,
  moveNotAllowed,

  fight,
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
    await fight(contract, [challenger, defender], [x`1c`]);
    await expectPlayers(contract, defender, challenger);
  });

  it("Should not allowed to challenge with a challenge in effect", async function () {
    await fight(contract, [challenger, defender], [x`1c`]);
    await expectPlayers(contract, defender, challenger);
    await moveNotAllowed(contract, bystander, "challenge", wrong.playing);
  });

  it("Should be able to defend with a challenge in effect", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`]);
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    await expectNoPlayers(contract);
    await moveNotAllowed(contract, defender, "defend");

    await init(contract, defender);
    await moveNotAllowed(contract, defender, "defend");

    await challenge(contract, challenger, defender);
    await moveNotAllowed(contract, bystander, "defend", wrong.you);
  });

  it("Should be able to reveal challenge with defend in effect", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`, `1c`]);
  });

  it("Should be able to reveal defend with revealed challenge", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`, `1c`, `1d`]);
  });

  it("Should be able to claim winning if defender wins", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`, `1c`, `1d`]);

    await expectWinner(contract, defender);
    await claimWinning(contract, defender);
    await expectPlayers(contract, defender, nobody);
  });

  it("Should be able to claim winning if challenger wins", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`0d`, `1c`, `0d`]);

    await expectWinner(contract, challenger);
    await claimWinning(contract, challenger);
    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if defender did not response #1 defend", async function () {
    await fight(contract, [challenger, defender], [x`1c`]);
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, challenger);
    await mineBlocks(150);
    await claimWinning(contract, challenger);

    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if defender did not response #1 reveal", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`, `1c`]);
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, challenger);
    await mineBlocks(150);
    await claimWinning(contract, challenger);

    await expectPlayers(contract, challenger, nobody);
  });

  it("Should be able to claim winning if challenger did not response #2 reveal", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`1d`]);
    await expectWinner(contract, nobody);

    await cannotClaimWinning(contract, defender);
    await mineBlocks(150);
    await claimWinning(contract, defender);

    await expectPlayers(contract, defender, nobody);
  });

  it("Should be able to start a new game after last game settled", async function () {
    await fight(contract, [challenger, defender], [x`1c`, x`0d`, `1c`, `0d`]);

    await expectWinner(contract, challenger);
    await challenge(contract, bystander, challenger);
    await expectPlayers(contract, challenger, bystander);
  });

  // Once win, the winner is the winner

  // TODO: Keep the winner the winner if all states recorded
  // Challenger first, Winner first.
  // Who left the game, who forever lost

  // TODO: forwarders
  // TODO: MAX_STATES == 0, infinite game, customized game ending indicator
});
