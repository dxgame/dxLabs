// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./GameManager.sol";
import "./CircularManager.sol";

contract SeatManager {
    struct Seat {
        uint256 id;
        address player;
        uint nextMoveDeadline;
    }
}

abstract contract TourneyManager is GameManager, SeatManager, CircularManager {
    struct Tourney {
        uint256 id;
        Game[] games;
        CircularList circular;
        mapping (uint256 => Seat) seats;
    }

    function registerTourney(Tourney storage tourney, address player) internal {
        uint256 id = addCircularNode(tourney.circular);
        tourney.seats[id] = Seat(id, player, 0);
    }

    function markSeatLost(Tourney storage tourney, uint256 id) internal {
        removeCircularNode(tourney.circular, id);
    }

    function countSurvivors(Tourney storage tourney) internal view returns (uint count) {
        return countCircularList(tourney.circular);
    }
}
