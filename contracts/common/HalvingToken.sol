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

    function mint(address player) internal {
        uint256 periods = mintCounter / halvingPeriod;
        uint256 amount = initialAmount / (2 ** periods);
        _mint(player, amount);

        mintCounter ++;
    }
}
