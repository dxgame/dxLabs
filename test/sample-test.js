const { expect } = require("chai");
const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

describe("SimpleToken", async function () {
  let contract;
  const [, addr1] = await ethers.getSigners();

  beforeEach(async function () {
    const Contract = await ethers.getContractFactory("SimpleToken");
    contract = await Contract.deploy(N`10`);
    await contract.deployed();
  });

  it("Should return the new totalSupply once it's changed", async function () {
    expect(await contract.totalSupply()).to.equal(N`10`);
    const mintTx = await contract.mint(N(1));
    await mintTx.wait();
    expect(await contract.totalSupply()).to.equal(N`11`);
  });

  it("Should throw error mint by no owner", async function () {
    await expect(contract.connect(addr1).mint(N`10`)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });
});
