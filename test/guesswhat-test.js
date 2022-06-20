const { expect } = require("chai");
const { ethers } = require("hardhat");

const { N, prepare, tx } = require("./utils");

describe("GuessWhat", function () {
  let contract, addr1;

  beforeEach(async function () {
    [contract, , addr1] = await prepare("GuessWhat", N`10`);
  });

  it("Should update defender with a new challenge", async function () {
    expect(await contract.defender()).to.equal(ethers.constants.AddressZero);

    await tx(
      contract
        .connect(addr1)
        .challenge(ethers.utils.formatBytes32String("Hello World!"))
    );

    expect(await contract.defender()).to.equal(addr1);
  });
});
