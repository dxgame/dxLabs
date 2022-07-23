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
        mapping (uint256 => Game) games;
    }

    event StartTourneyGame(uint256 gameId, uint256 challengerSeatId, uint256 defenderSeatId);

    function registerTourneySeat(
        Tourney storage tourney,
        address player
    ) internal {
        require(tourney.registerDeadline >= block.number, "Tourney registration is closed");
        uint256 id = addCircularNode(tourney.circular);
        tourney.seats[id] = player;
    }

    function startTouneyGame(
        Tourney storage tourney,
        uint256 challengerSeatId,
        uint256 defenderSeatId,
        string memory initialState,
        address player
    ) internal {
        require(tourney.seats[challengerSeatId] == player, "Only the challenger can start the game");
    
        uint256 gameId = getTourneyGameId(tourney.id, challengerSeatId, defenderSeatId);
        require(tourney.games[gameId].states.length == 0, "Game already started");
    
        startGame(tourney.games[gameId], initialState, challengerSeatId, defenderSeatId);
        emit StartTourneyGame(gameId, challengerSeatId, defenderSeatId);
    }

    function playTourneyGame(
        Tourney storage tourney,
        uint256 gameId,
        uint256 moveIndex,
        uint256 seatId,
        string memory state,
        address player
    ) internal {
        require(tourney.seats[seatId] == player, "Only the player can play the game");
        playGame(tourney.games[gameId], seatId, moveIndex, state);
    }

    function removeGameLoserSeat(Tourney storage tourney, uint256 gameId) internal {
        Game storage game = tourney.games[gameId];
        uint256 winner = determineGameWinner(game);
        if (winner == game.challenger) {
            removeCircularNode(tourney.circular, game.defender);
        }
        if (winner == game.defender) {
            removeCircularNode(tourney.circular, game.challenger);
        }
    }

    function determineTourneyWinner(Tourney storage tourney) internal view returns (address) {
        require(countTourneySurvivors(tourney) == 1, "Tourney has more than one winner");
        return tourney.seats[tourney.circular.head];
    }

    function countTourneySurvivors(Tourney storage tourney) internal view returns (uint count) {
        return countCircularList(tourney.circular);
    }

    function getTourneyGameId(uint256 tourneyId, uint256 seatId1, uint256 seatId2) internal pure returns (uint256) {
        uint256 smallOne = seatId1 < seatId2 ? seatId1 : seatId2;
        uint256 bigOne = seatId1 > seatId2 ? seatId1 : seatId2;
        return uint256(keccak256(abi.encodePacked(tourneyId, smallOne, " vs. ", bigOne)));
    }
}
