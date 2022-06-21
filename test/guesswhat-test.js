const { expect } = require("chai");
const { ethers } = require("hardhat");

const { N, prepare, tx, HashZero } = require("./utils");

describe("GuessWhat", function () {
  let contract, addr1, addr2, addr3;

  beforeEach(async function () {
    // const [stateLib] = await prepare("StateLib");
    const [gameLib] = await prepare("GameLib");
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

    await tx(contract.connect(addr1).challenge(HashZero));

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);
  });

  it("Should update challenger with a new challenge if there is defender", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(contract.connect(addr1).challenge(HashZero));
    await tx(contract.connect(addr2).challenge(HashZero));

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);
  });

  it("Should not allowed to challenge with a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(contract.connect(addr1).challenge(HashZero));
    await tx(contract.connect(addr2).challenge(HashZero));

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);

    await expect(
      contract.connect(addr3).challenge(HashZero)
    ).to.be.revertedWith("GuessWhat: move not allowed");
  });

  it("Should be able to defend with a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(contract.connect(addr1).challenge(HashZero));
    await tx(contract.connect(addr2).challenge(HashZero));

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(addr2.address);

    const preBlock = await ethers.provider.getBlock("latest");

    await expect(contract.connect(addr1).defend(HashZero))
      .to.emit(contract, "UpdateNextMoveEvent")
      .withArgs(
        2,
        addr1.address,
        addr2.address,
        preBlock.number + 1 + 200,
        preBlock.number + 1 + 400
      );
  });

  it("Should not be able to defend without a challenge in effect", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await expect(contract.connect(addr1).defend(HashZero)).to.be.revertedWith(
      "GuessWhat: move not allowed"
    );

    await tx(contract.connect(addr1).challenge(HashZero));
    await expect(contract.connect(addr1).defend(HashZero)).to.be.revertedWith(
      "GuessWhat: move not allowed"
    );

    await tx(contract.connect(addr2).challenge(HashZero));
    await expect(contract.connect(addr3).defend(HashZero)).to.be.revertedWith(
      "GuessWhat: you are not allowed"
    );
  });
});
