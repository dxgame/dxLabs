// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HalvingToken is ERC20 {
    uint256 public genesisBlock;
    uint256 public blocksPerMint;

    uint256 public mintCounter;
    uint256 public halvingPeriod;
    uint256 public initialAmount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _halvingPeriod,
        uint256 _initialAmount,
        uint256 _blocksPerMint
    ) ERC20(name, symbol) {
        genesisBlock = block.number;
        halvingPeriod = _halvingPeriod;
        initialAmount = _initialAmount;
        blocksPerMint = _blocksPerMint;
    }

    function blocksPassed() internal view returns (uint256) {
        return block.number - genesisBlock;
    }

    function maxSupply() public view returns (uint256) {
        return initialAmount * 2 * halvingPeriod;
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply();
    }

    function mint(address player, uint256 _mintCounter) internal {
        require(_mintCounter > mintCounter, "Mint counter must increase");
        require(blocksPassed() >= _mintCounter * blocksPerMint, "Mint too fast");

        uint256 periods = mintCounter / halvingPeriod;
        uint256 amount = initialAmount / (2 ** periods);
        _mint(player, amount);

        mintCounter = _mintCounter;
    }
}
