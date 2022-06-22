const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

const tx = async function (_tx) {
  return (await _tx).wait();
};

const hashHex = (str) =>
  ethers.utils.solidityKeccak256(["string"], [str.toString()]);

const { HashZero, AddressZero } = ethers.constants;

const nobody = { address: AddressZero };

module.exports = {
  N,
  tx,
  hashHex,
  x: hashHex,
  HashZero,
  AddressZero,
  nobody,
};
