const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

const prepare = async function (contractName, ...args) {
  const signers = await ethers.getSigners();
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(...args);
  await contract.deployed();
  return [contract, ...signers];
};

const tx = async function (_tx) {
  return (await _tx).wait();
};

module.exports = {
  N,
  prepare,
  tx,
};
