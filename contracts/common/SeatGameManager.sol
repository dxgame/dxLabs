// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*
    To indicate who wins the game:

        use MAX_BLOCKS_PER_MOVE and whoWins

        if one player were late by MAX_BLOCKS_PER_MOVE, same as NO SHOW
            the last player wins

        if game finished
            the winner will be determined by cutomized game-specific function whoWins

    To indicate when the game is finished:

        use MAX_STATES or isGameFinished

        You must set MAX_STATES to the number of steps in the game.
        or override isGameFinished() to customize the game-specific finished condition.

    // TODO: use channel id & state no to identify the move
    // TODO: maybe StateChannelManager ?
 */

abstract contract SeatGameManager {
    struct Game {
        uint256 id;
        uint256 MAX_STATES;
        uint256 MAX_BLOCKS_PER_MOVE;

        uint256 challenger;
        uint256 defender;
        string[] states;

        uint256 nextMoveDeadline;
    }

    event StartGameEvent(
        uint256 indexed id,
        uint256 indexed challenger,
        uint256 indexed defender
    );
    event UpdateStateEvent(
        uint256 indexed id,
        uint256 indexed player,
        uint256 indexed nextPlayer,
        uint256 nextMoveDeadline
    );

    function isGameStarted(
        Game storage game
    ) internal view returns (bool) {
        return game.states.length != 0;
    }

    function isGameFinished(
        Game storage game
    ) internal view virtual returns (bool) {
        return game.MAX_STATES != 0 && game.states.length == game.MAX_STATES;
    }

    function isGameHalfway(
        Game storage game
    ) internal view returns(bool) {
        return isGameStarted(game) && !isGameFinished(game);
    }

    function isGamePlaying(
        Game storage game
    ) internal view returns(bool) {
        return isGameHalfway(game) && (block.number <= game.nextMoveDeadline);
    }

    function isGameStoppedHalfway(
        Game storage game
    ) internal view returns (bool) {
        return isGameHalfway(game) && (block.number > game.nextMoveDeadline);
    }

    function getGameOpponent(
        Game storage game,
        uint256 player
    ) internal view returns (uint256) {
        if (player == game.challenger) {
            return game.defender;
        }
        if (player == game.defender) {
            return game.challenger;
        }
        revert("Player is not a part of this game");
    }

    function getGameNextPlayer(
        Game storage game
    ) internal view returns (uint256) {
        uint256 player = _lastPlayer(game);
        return getGameOpponent(game, player);
    }

    function getGameNextMoveIndex(
        Game storage game
    ) internal view returns (uint256) {
        require(isGamePlaying(game), "DxGame: move not allowed");
        return game.states.length;
    }

    function startGame(
        Game storage game,
        string memory state,
        uint256 challenger,
        uint256 defender
    ) internal {
        require(game.states.length == 0, "DxGame: game already started");
        game.challenger = challenger;
        game.defender = defender;
        _pushState(game, state);
        emit StartGameEvent(game.id, challenger, defender);
    }

    function playGame(
        Game storage game,
        string memory state
    ) internal {
        require(game.states.length > 0, "DxGame: game not started");
        require(block.number <= game.nextMoveDeadline, "DxGame: you are too late");
        require(!isGameFinished(game), "DxGame: game already finished");

        _pushState(game, state);
    }

    function getGameWinner(Game storage game) internal view returns (uint256) {
        if (isGameStoppedHalfway(game)) {
            return _lastPlayer(game);
        }
        if (isGameFinished(game)) {
            return whoWinsTheGame(game);
        }
        revert("DxGame: game not finished");
    }

    function whoWinsTheGame(
        Game storage game
    ) internal view virtual returns (uint256);

    function _lastState(
        Game storage game
    ) private view returns (string storage){
        return game.states[game.states.length - 1];
    }

    function _lastPlayer(
        Game storage game
    ) private view returns (uint256) {
        return game.states.length % 2 == 1 ? game.challenger : game.defender;
    }

    function _nextPlayer(
        Game storage game
    ) private view returns (uint256) {
        return game.states.length % 2 == 0 ? game.challenger : game.defender;
    }

    function _pushState(
        Game storage game,
        string memory state
    ) private {
        game.states.push(state);
        game.nextMoveDeadline = block.number + game.MAX_BLOCKS_PER_MOVE;

        emit UpdateStateEvent(
            game.id,
            _lastPlayer(game),
            _nextPlayer(game),
            game.nextMoveDeadline
        );
    }
}
