// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./GameManager.sol";

abstract contract TourneyManager is GameManager {
    struct Seat {
        address player;
        uint nextMoveDeadline;
    }

    Game[] games;
    address[] players;
    mapping(uint256 => address) seats;

    // seats in losersZone will not be able to participate the next round;
    mapping(uint256 => bool) losersZone;

    function finalWinner() public returns (uint256) {

    }
}