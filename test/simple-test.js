const { expect } = require("chai");
const { N, prepare } = require("./utils");

describe("SimpleToken", function () {
  let contract, addr1;

  beforeEach(async function () {
    [contract, , addr1] = await prepare("SimpleToken", {}, N`10`);
  });

  it("Should return the new totalSupply once it's changed", async function () {
    expect(await contract.totalSupply()).to.equal(N`10`);
    const mintTx = await contract.mint(N(1));
    await mintTx.wait();
    expect(await contract.totalSupply()).to.equal(N`11`);
  });

  it("Should revert when mint by not-owner", async function () {
    await expect(contract.connect(addr1).mint(N`10`)).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });
});
