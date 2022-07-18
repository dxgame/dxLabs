// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HalvingToken is ERC20 {
    uint256 public mintCounter;
    uint256 public halvingPeriod;
    uint256 public initialAmount;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _halvingPeriod,
        uint256 _initialAmount
    ) ERC20(name, symbol) {
        halvingPeriod = _halvingPeriod;
        initialAmount = _initialAmount;
    }

    function maxSupply() public view returns (uint256) {
        return initialAmount * 2 * halvingPeriod;
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply();
    }

    function mint(address player, uint256 _mintCounter) internal {
        require(_mintCounter > mintCounter, "Mint counter must increase");

        uint256 periods = mintCounter / halvingPeriod;
        uint256 amount = initialAmount / (2 ** periods);
        _mint(player, amount);

        mintCounter = _mintCounter;
    }
}
