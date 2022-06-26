const prepare = require("./utils/prepare");
const { N, nobody, x, mineBlocks } = require("./utils/common");
const {
  wrong,
  expectPlayers,
  moveNotAllowed,
  fight,
  init,
  failMessSignsMove,
  challenge,
  claimWinning,
} = require("./utils/guesswhat");

describe("GuessWhat", function () {
  let gamers;
  let contract, deployer, defender, challenger, bystander, forwarder;

  beforeEach(async function () {
    const preparation = await prepare("GuessWhat", "GameLib", N`10`);
    [contract, deployer, defender, challenger, bystander, forwarder] =
      preparation;
    gamers = { deployer, defender, challenger, bystander, forwarder };
  });

  // TODO: refactor this test, with groups
  describe("#0 init", async function () {
    it("Should update defender with a new challenge if there's no defender", async function () {
      await init(contract, defender);
      await expectPlayers(contract, defender, nobody);
    });

    it("Should update defender with a new challenge if there's no defender # with forwarder", async function () {
      await init(contract, defender, forwarder);
      await expectPlayers(contract, defender, nobody);
    });

    it("Should fail with messed up params", async function () {
      await failMessSignsMove(contract, defender, "challenge");
    });
  });

  describe("#1 challenge", async function () {
    it("Should update challenger with a new challenge if there is defender", async function () {
      await fight(contract, gamers, [x`1c`]);
      await expectPlayers(contract, defender, challenger);
    });

    it("Should fail with messed up params", async function () {
      await init(contract, defender, forwarder);
      await failMessSignsMove(contract, challenger, "challenge");
    });

    it("Should not be allowed to challenge with a challenge in effect", async function () {
      await fight(contract, gamers, [x`1c`]);
      await moveNotAllowed(contract, bystander, "challenge", wrong.playing);
    });

    it("Should not be allowed to challenge with a defend in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await moveNotAllowed(contract, bystander, "challenge", wrong.playing);
    });

    it("Should not be allowed to challenge with a revealedChallenge in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`]);
      await moveNotAllowed(contract, bystander, "challenge", wrong.playing);
    });

    it("Should be allowed to challenge with last game no response # challenge", async function () {
      await fight(contract, gamers, [x`1c`]);
      await mineBlocks(150);
      await challenge(contract, bystander, challenger, x`1b`);
    });

    it("Should be allowed to challenge with last game no response # defend", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await mineBlocks(150);
      await challenge(contract, bystander, defender, x`1b`);
    });

    it("Should be allowed to challenge with last game no response # revealedChallenge", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`]);
      await mineBlocks(150);
      await challenge(contract, bystander, challenger, x`1b`);
    });

    it("Should be allowed to challenge with a revealedDefend in effect # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`, `1d`]);
      await challenge(contract, bystander, defender, x`1b`);
    });

    it("Should be allowed to challenge with a revealedResponse in effect # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`sd`, `1c`, `sd`]);
      await challenge(contract, bystander, challenger, x`1b`);
    });
  });

  describe("#2 defend", async function () {
    it("Should be able to defend with a challenge in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
    });

    it("Should fail with messed up params", async function () {
      await fight(contract, gamers, [x`1c`]);
      await failMessSignsMove(contract, defender, "defend");
    });

    it("Should fail if you are late", async function () {
      await fight(contract, gamers, [x`1c`]);
      await mineBlocks(150);
      await moveNotAllowed(contract, defender, "defend", wrong.late);
    });

    it("Should fail if you are not the defender", async function () {
      await fight(contract, gamers, [x`1c`]);
      await moveNotAllowed(contract, bystander, "defend", wrong.you);
    });

    it("Should not be allowed to defend with a defend in effect #1 defender", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await moveNotAllowed(contract, defender, "defend", wrong.move);
    });

    it("Should not be allowed to defend with a defend in effect #2 bystander", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await moveNotAllowed(contract, bystander, "defend", wrong.move);
    });

    it("Should not be allowed to defend with a revealedChallenge in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`]);
      await moveNotAllowed(contract, bystander, "defend", wrong.move);
    });

    it("Should not be allowed to defend with a revealedDefend in effect # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`, `1d`]);
      await moveNotAllowed(contract, bystander, "defend", wrong.move);
    });

    it("Should not be allowed to defend with a revealedResponse in effect # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`sd`, `1c`, `sd`]);
      await moveNotAllowed(contract, bystander, "defend", wrong.move);
    });
  });

  describe("#3 revealChallenge", async function () {
    it("Should be able to reveal challenge with a defend in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
    });

    it("Should fail with messed up params", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await failMessSignsMove(contract, challenger, "revealChallenge");
    });

    it("Should fail if you are late", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await mineBlocks(150);
      await moveNotAllowed(
        contract,
        challenger,
        "revealChallenge",
        wrong.late,
        { message: "1c" }
      );
    });

    it("Should fail if you are not the challenger", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await moveNotAllowed(contract, bystander, "revealChallenge", wrong.you, {
        message: "1c",
      });
    });

    it("Should fail if messages do not match", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await moveNotAllowed(
        contract,
        bystander,
        "revealChallenge",
        wrong.match,
        {
          message: "1",
        }
      );
    });

    it("Should not be allowed to reveal with a reveal in effect #1 challenger", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await moveNotAllowed(contract, challenger, "revealChallenge", wrong.move);
    });

    it("Should not be allowed to reveal with a reveal in effect #2 bystander", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await moveNotAllowed(contract, bystander, "revealChallenge", wrong.move);
    });

    it("Should not be allowed to reveal if game finished # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`, `1d`]);
      await moveNotAllowed(contract, challenger, "revealChallenge", wrong.move);
    });

    it("Should not be allowed to reveal if game finished # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`, `1c`, `xd`]);
      await moveNotAllowed(contract, challenger, "revealChallenge", wrong.move);
    });
  });

  describe("#4 revealDefend", async function () {
    it("Should be able to reveal defend with a revealed challenge in effect", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c", "1d"]);
    });

    it("Should fail with messed up params", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await failMessSignsMove(contract, defender, "revealDefend", {
        message: "1d",
      });
    });

    it("Should fail if you are late", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await mineBlocks(150);
      await moveNotAllowed(contract, defender, "revealDefend", wrong.late, {
        message: "1d",
      });
    });

    it("Should fail if you are not the defender", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await moveNotAllowed(contract, bystander, "revealDefend", wrong.you, {
        message: "1d",
      });
    });

    it("Should fail if messages do not match", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await moveNotAllowed(contract, defender, "revealDefend", wrong.match, {
        message: "1x",
      });
    });

    it("Should not be allowed to reveal if game finished # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, `1c`, `1d`]);
      await moveNotAllowed(contract, defender, "revealDefend", wrong.move);
    });

    it("Should not be allowed to reveal if game finished # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`, `1c`, `xd`]);
      await moveNotAllowed(contract, defender, "revealDefend", wrong.move);
    });
  });

  describe("#5 claimWinning", async function () {
    it("Should be able to claim winning after game finished # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c", "1d"]);
      await claimWinning(contract, defender, bystander);
    });

    it("Should be able to claim winning after game finished # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`, "1c", "xd"]);
      await claimWinning(contract, challenger, bystander);
    });

    it("Should fail with messed up params", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c", "1d"]);
      await failMessSignsMove(contract, bystander, "claimWinning");
    });

    it("Should fail if game not started yet", async function () {
      await moveNotAllowed(contract, bystander, "claimWinning", wrong.noGame);
    });

    it("Should fail if game not finished yet #1 challenge", async function () {
      await fight(contract, gamers, [x`1c`]);
      await moveNotAllowed(contract, bystander, "claimWinning", wrong.playing);
    });

    it("Should fail if game not finished yet #2 defend", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`]);
      await moveNotAllowed(contract, bystander, "claimWinning", wrong.playing);
    });

    it("Should fail if game not finished yet #3 revealChallenge", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`, "1c"]);
      await moveNotAllowed(contract, bystander, "claimWinning", wrong.playing);
    });

    it("Should be able to claim winning if no response # challenge", async function () {
      await fight(contract, gamers, [x`1c`]);
      await mineBlocks(150);
      await claimWinning(contract, challenger, bystander);
    });

    it("Should be able to claim winning if no response # defend", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`]);
      await mineBlocks(150);
      await claimWinning(contract, defender, bystander);
    });

    it("Should be able to claim winning if no response # reveal challenge", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c"]);
      await mineBlocks(150);
      await claimWinning(contract, challenger, bystander);
    });

    it("Should be able to claim winning if no response after game finished # defender won", async function () {
      await fight(contract, gamers, [x`1c`, x`1d`, "1c", "1d"]);
      await mineBlocks(150);
      await claimWinning(contract, defender, bystander);
    });

    it("Should be able to claim winning if no response after game finished # challenger won", async function () {
      await fight(contract, gamers, [x`1c`, x`xd`, "1c", "xd"]);
      await mineBlocks(150);
      await claimWinning(contract, challenger, bystander);
    });
  });
});
