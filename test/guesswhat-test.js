const { expect } = require("chai");
const { ethers } = require("hardhat");

const { N, prepare, tx, HashZero } = require("./utils");

describe("GuessWhat", function () {
  let contract, addr1, addr2, addr3;

  beforeEach(async function () {
    [contract, , addr1, addr2, addr3] = await prepare("GuessWhat", N`10`);
  });

  it("Should update defender with a new challenge without defender", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);

    await tx(contract.connect(addr1).challenge(HashZero));

    expect(await contract.defender()).to.equal(addr1.address);
    expect(await contract.challenger()).to.equal(ethers.constants.AddressZero);
  });

  it("Should update challenger with a new challenge with a defender", async function () {
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
});
