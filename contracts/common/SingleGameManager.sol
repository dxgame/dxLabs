// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./GameManager.sol";

abstract contract SingleGameManager is GameManager {
    Game public game;

    constructor() {
        game.MAX_BLOCKS_PER_MOVE = 100;
    }

    function challenger() public view returns (address) {
        return getGameChallenger(game);
    }

    function defender() public view returns (address) {
        return getGameDefender(game);
    }

    function nextPlayer() public view returns (address) {
        return getGameNextPlayer(game);
    }

    function opponent(address player) public view returns (address) {
        return getGameOpponent(game, player);
    }

    function lastStateHash() public view returns (bytes32) {
        return getGameLastStateHash(game);
    }

    function claimWinning(
        bytes32 prehash, address player, string memory message, uint8 v, bytes32 r, bytes32 s
    ) external {
        State memory state = stateCheckIn(prehash, player, message, v, r, s);

        claimWinningGame(game, state);
    }

    modifier startable() {
        require(isGameNotStarted(game) || isGameStopped(game) || isGameFinished(game), "DxGame: somebody playing");
        _;
    }
}
