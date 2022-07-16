// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./CircularManager.sol";
import "./GameChannelManager.sol";

abstract contract TourneyManager is CircularManager, GameChannelManager {
    struct Tourney {
        uint256 id;
        uint256 registerDeadline;

        CircularList circular;
        mapping (uint256 => address) seats;
        mapping (uint256 => Game[]) games;
    }

    event StartTourneyGame(uint256 gameId, uint256 challengerSeatId, uint256 defenderSeatId);

    function registerTourneySeat(Tourney storage tourney, address player) internal {
        require(tourney.registerDeadline >= block.number, "Tourney registration is closed");
        uint256 id = addCircularNode(tourney.circular);
        tourney.seats[id] = player;
    }

    function startTouneyGame(Tourney storage tourney, uint256 challengerSeatId, uint256 defenderSeatId, string memory initialState) internal {
        uint256 gameId = getTourneyGameId(tourney.id, challengerSeatId, defenderSeatId);
        require(tourney.games[gameId].length == 0, "Game already started");

        // TODO
        Game storage game = tourney.games[gameId];

        tourney.games[gameId].push(initialState);
        emit StartTourneyGame(gameId, challengerSeatId, defenderSeatId);
    }

    function playTourneyGame(Tourney storage tourney, uint256 gameId, string memory state) internal {
        tourney.games[gameId].push(state);
    }

    function removeTourneySeat(Tourney storage tourney, uint256 seatId) internal {
        removeCircularNode(tourney.circular, seatId);
    }

    /* - */

    function countTourneySurvivors(Tourney storage tourney) internal view returns (uint count) {
        return countCircularList(tourney.circular);
    }

    function getTourneyGame(Tourney storage tourney, uint256 seatId1, uint256 seatId2) internal view returns (string[] storage) {
        uint256 gameId = getTourneyGameId(tourney.id, seatId1, seatId2);
        return tourney.games[gameId];
    }

    function getTourneyGameId(uint256 tourneyId, uint256 seatId1, uint256 seatId2) internal pure returns (uint256) {
        uint256 smallOne = seatId1 < seatId2 ? seatId1 : seatId2;
        uint256 bigOne = seatId1 > seatId2 ? seatId1 : seatId2;
        return uint256(keccak256(abi.encodePacked(tourneyId, smallOne, " vs. ", bigOne)));
    }
}
