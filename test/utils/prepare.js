const { ethers } = require("hardhat");

const prepareLibs = async function (libraries) {
  if (typeof libraries === "string") {
    const [library] = await prepare(libraries);
    return { [libraries]: library.address };
  }
  return libraries;
};

const prepare = async function (contractName, libraries, ...args) {
  libraries = await prepareLibs(libraries);

  const signers = await ethers.getSigners();
  const Contract = await ethers.getContractFactory(contractName, { libraries });
  const contract = await Contract.deploy(...args);

  await contract.deployed();
  return [contract, ...signers];
};

module.exports = prepare;
