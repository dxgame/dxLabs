const { ethers } = require("hardhat");

const N = (n) => ethers.utils.parseEther(n.toString());

const tx = async function (_tx) {
  return (await _tx).wait();
};

function hashHex(str) {
  return ethers.utils.solidityKeccak256(["string"], [str]);
}

const { HashZero, AddressZero } = ethers.constants;

const nobody = { address: AddressZero };

module.exports = {
  N,
  tx,
  hashHex,
  HashZero,
  AddressZero,
  nobody,
};
