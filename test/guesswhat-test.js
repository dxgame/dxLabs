const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
  N,
  prepare,
  tx,
  StateLib,
  getUpdateStateEventArgs,
  challenge,
} = require("./utils");

describe("GuessWhat", function () {
  let gameLib, contract, addr1, addr2, addr3;

  beforeEach(async function () {
    [gameLib] = await prepare("GameLib");
    const libraries = { GameLib: gameLib.address };
    [contract, , addr1, addr2, addr3] = await prepare(
      "GuessWhat",
      libraries,
      N`10`
    );
  });

  it("Should update defender with a new challenge if there's no defender", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(
      contract
        .connect(addr1)
        .challenge(...(await StateLib.getParams({ signer: addr1 })))
    );

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);
  });

  it("Should update challenger with a new challenge if there is defender", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(
      contract
        .connect(addr1)
        .challenge(...(await StateLib.getParams({ signer: addr1 })))
    );
    await tx(
      contract
        .connect(addr2)
        .challenge(...(await StateLib.getParams({ signer: addr2 })))
    );

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);
  });

  it("Should not allowed to challenge with a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(
      contract
        .connect(addr1)
        .challenge(...(await StateLib.getParams({ signer: addr1 })))
    );
    await tx(
      contract
        .connect(addr2)
        .challenge(...(await StateLib.getParams({ signer: addr2 })))
    );

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);

    await expect(
      contract
        .connect(addr3)
        .challenge(...(await StateLib.getParams({ signer: addr3 })))
    ).to.be.revertedWith("GuessWhat: move not allowed");
  });

  it("Should be able to defend with a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(
      contract
        .connect(addr1)
        .challenge(...(await StateLib.getParams({ signer: addr1 })))
    );
    await tx(
      contract
        .connect(addr2)
        .challenge(...(await StateLib.getParams({ signer: addr2 })))
    );

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);

    const preBlock = await ethers.provider.getBlock("latest");
    const prevHash = await contract.lastStateHash();
    const game = await contract.game();
    const MAX_BLOCKS_PER_MOVE = game.MAX_BLOCKS_PER_MOVE.toNumber();

    await expect(
      contract
        .connect(addr1)
        .defend(...(await StateLib.getParams({ prevHash, signer: addr1 })))
    )
      .to.emit(contract, "UpdateStateEvent")
      .withArgs(
        game.id,
        game.round,
        2,
        addr1.address,
        addr2.address,
        preBlock.number + 1 + MAX_BLOCKS_PER_MOVE,
        preBlock.number + 1 + MAX_BLOCKS_PER_MOVE * 2
      );
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await expect(
      contract
        .connect(addr1)
        .defend(...(await StateLib.getParams({ signer: addr1 })))
    ).to.be.revertedWith("GuessWhat: move not allowed");

    await tx(
      contract
        .connect(addr1)
        .challenge(...(await StateLib.getParams({ signer: addr1 })))
    );
    await expect(
      contract
        .connect(addr1)
        .defend(...(await StateLib.getParams({ signer: addr1 })))
    ).to.be.revertedWith("GuessWhat: move not allowed");

    await tx(
      contract
        .connect(addr2)
        .challenge(...(await StateLib.getParams({ signer: addr2 })))
    );
    await expect(
      contract
        .connect(addr3)
        .defend(...(await StateLib.getParams({ signer: addr3 })))
    ).to.be.revertedWith("GuessWhat: not for you now");
  });

  it("Should be able to reveal challenge with defend in effect", async function () {
    await challenge(contract, addr2, addr1);

    await expect(
      contract.connect(addr1).defend(
        ...(await StateLib.getParams({
          prevHash: await contract.lastStateHash(),
          signer: addr1,
        }))
      )
    )
      .to.emit(contract, "UpdateStateEvent")
      .withArgs(...(await getUpdateStateEventArgs(contract, addr1, addr2, 2)));
  });

  // TODO: reveal challenge
});
