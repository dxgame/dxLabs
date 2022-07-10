// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./StateManager.sol";
import "./CircularManager.sol";

abstract contract TourneyManager is StateManager, CircularManager {
    struct Tourney {
        uint256 id;
        CircularList circular;
        mapping (uint256 => address) seats;
        mapping (uint256 => State[]) games;
    }

    function registerTourney(Tourney storage tourney, address player) internal {
        uint256 id = addCircularNode(tourney.circular);
        tourney.seats[id] = player;
    }

    function markSeatLost(Tourney storage tourney, uint256 id) internal {
        removeCircularNode(tourney.circular, id);
    }

    function countSurvivors(Tourney storage tourney) internal view returns (uint count) {
        return countCircularList(tourney.circular);
    }
}
