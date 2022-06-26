const hardhatRuntimeEnvironment = require("hardhat");

const { ethers } = hardhatRuntimeEnvironment;

const N = (n) => ethers.utils.parseEther(n.toString());

const tx = async function (_tx) {
  return (await _tx).wait();
};

const mineBlocks = (n = 100, s = 1) => {
  return hardhatRuntimeEnvironment.network.provider.send("hardhat_mine", [
    ethers.utils.hexStripZeros(n),
    ethers.utils.hexStripZeros(s),
  ]);
};

const hashHex = (str) =>
  ethers.utils.solidityKeccak256(["string"], [str.toString()]);

const messHexStr = (str) => str.replace(/0x.{16}/, "0x0123456789abcdef");

const { HashZero, AddressZero } = ethers.constants;

const nobody = { address: AddressZero };

module.exports = {
  mineBlocks,
  N,
  tx,
  hashHex,
  x: hashHex,
  messHexStr,
  HashZero,
  AddressZero,
  nobody,
};
