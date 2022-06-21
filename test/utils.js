const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

const prepare = async function (contractName, libraries, ...args) {
  const signers = await ethers.getSigners();
  const Contract = await ethers.getContractFactory(contractName, { libraries });
  const contract = await Contract.deploy(...args);

  await contract.deployed();
  return [contract, ...signers];
};

const tx = async function (_tx) {
  return (await _tx).wait();
};

const HashZero = ethers.constants.HashZero;

module.exports = {
  N,
  prepare,
  tx,
  HashZero,
};
