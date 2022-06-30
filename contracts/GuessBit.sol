// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/GuessWhat.sol";

/*
    GuessWhat of [0, 1]

    step 1: challenger starts new challenge
    step 2: defender defends
    step 3: challenger reveals
    step 4: defender reveals
*/

contract GuessBit is Ownable, ERC20, GuessWhat {
    constructor(
        uint256 initialSupply
    )
        ERC20("GuessBit", "GSWT")
        GuessWhat(1)
    {
        _mint(msg.sender, initialSupply);
    }
}

