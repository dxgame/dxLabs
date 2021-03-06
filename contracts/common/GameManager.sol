// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./StateManager.sol";

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

    // TODO: GAME SCRIPTS - programmable game-specific function to help users make more games
 */

abstract contract GameManager is StateManager {
    struct Game {
        uint256 id;
        uint256 round;

        uint256 MAX_STATES;
        uint256 MAX_BLOCKS_PER_MOVE;
 
        address winner;
        address[2] players;
        State[] states;

        uint256 nextMoveDeadline;
    }

    event ResetEvent(
        uint256 indexed id,
        uint256 indexed round,
        address player
    );
    event StartEvent(
        uint256 indexed id,
        uint256 round,
        address indexed challenger,
        address indexed defender
    );
    event WinningEvent(
        uint256 indexed id,
        uint256 round,
        address indexed winner,
        address indexed announcer
    );
    event UpdateStateEvent(
        uint256 indexed id,
        uint256 round,
        uint256 states,
        address indexed player,
        address indexed getGameNextPlayer,
        uint256 nextMoveDeadline
    );

    function getGameChallenger(
        Game storage game
    ) internal view returns (address) {
        return game.players[0];
    }

    function getGameDefender(
        Game storage game
    ) internal view returns (address) {
        return game.winner;
    }

    function noDefender(
        Game storage game
    ) internal view returns (bool) {
        return getGameDefender(game) == address(0);
    }

    function isGameNotStarted(
        Game storage game
    ) internal view returns (bool) {
        return game.states.length == 0;
    }

    function isGameStarted(
        Game storage game
    ) internal view returns (bool) {
        return game.states.length != 0;
    }

    function isGameHalfway(
        Game storage game
    ) internal view returns(bool) {
        return isGameStarted(game) && !isGameFinished(game);
    }

    function isPlaying(
        Game storage game
    ) internal view returns(bool) {
        return isGameHalfway(game) && (block.number <= game.nextMoveDeadline);
    }

    function isGameStopped(
        Game storage game
    ) internal view returns (bool) {
        return isGameHalfway(game) && (block.number > game.nextMoveDeadline);
    }

    function isGameFinished(
        Game storage game
    ) internal view virtual returns (bool) {
        return game.MAX_STATES != 0 && game.states.length == game.MAX_STATES;
    }

    function stoppedPlaying(
        Game storage game
    ) internal view returns(bool) {
        return isGameStopped(game) || isGameFinished(game);
    }

    function notPlaying(
        Game storage game
    ) internal view returns(bool) {
        return !isPlaying(game);
    }

    function getGameOpponent(
        Game storage game,
        address player
    ) internal view returns (address) {
        if (game.players[0] == player) return game.players[1];
        if (game.players[1] == player) return game.players[0];
        return address(0);
    }

    function getGameNextPlayer(
        Game storage game
    ) internal view returns (address) {
        address player = _lastPlayer(game);
        return getGameOpponent(game, player);
    }

    function getGameNextMoveIndex(
        Game storage game
    ) internal view beforeDeadline(game) returns (uint256) {
        require(isPlaying(game), "DxGame: move not allowed");
        return game.states.length;
    }

    function getGameLastStateHash(
        Game storage game
    ) internal view returns (bytes32) {
        if (isGameStarted(game)) {
            return getStateHash(_lastState(game));
        }
        return keccak256(abi.encodePacked(
            address(this),
            blockhash(block.number - 1),
            msg.sender,
            game.id,
            game.round
        ));
    }

    function startGame(
        Game storage game,
        State memory state
    ) internal {
        require(notPlaying(game), "DxGame: somebody playing");

        if (stoppedPlaying(game)) {
            claimWinningGame(game, state);
        }

        noDefender(game)
            ? _announceWinningGame(game, state.player, state.player)
            : _startGame(game, state);
    }

    function playGame(
        Game storage game,
        State memory state
    ) internal {
        require(isPlaying(game), "DxGame: move not allowed");
        _pushState(game, state);
    }

    function claimWinningGame(
        Game storage game,
        State memory state
    ) internal notEmpty(game) {
        require(getGameLastStateHash(game) == state.prevHash, "DxGame: hash not right");
        require(stoppedPlaying(game), "DxGame: somebody playing");

        address winner = isGameStopped(game) ? _lastPlayer(game) : whoWins(game);
        if (winner == address(0)) revert("DxGame: nobody won");

        _announceWinningGame(game, winner, state.player);
        _resetGame(game, state.player);
    }

    function whoWins(
        Game storage _game
    ) internal view virtual returns (address);

    modifier notStarted(
        Game storage game
    ) {
        require(isGameNotStarted(game), "DxGame: game already started");
        _;
    }

    modifier notEmpty(
        Game storage game
    ) {
        require(isGameStarted(game), "DxGame: game not started");
        _;
    }

    modifier validDefender(
        Game storage game,
        address _defender
    ) {
        require(game.winner == address(0) || game.winner == _defender, "DxGame: defender should be the winner");
        _;
    }

    modifier beforeDeadline(
        Game storage game
    ) {
        require(game.nextMoveDeadline == 0 || block.number <= game.nextMoveDeadline, "DxGame: you are too late");
        _;
    }

    modifier validNewState(
        Game storage game,
        State memory state    
    ) {
        require(!isGameFinished(game), "DxGame: states overflow");
        _verifyChain(game, state);
        _;
    }

    function _lastState(
        Game storage game
    ) private view returns (State storage){
        return game.states[game.states.length - 1];
    }

    function _lastPlayer(
        Game storage game
    ) private view returns (address) {
        return _lastState(game).player;
    }

    function _verifyChain(
        Game storage game,
        State memory state
    ) private view {
        if (isGameNotStarted(game)) return;

        require(getGameNextPlayer(game) == state.player, "DxGame: not for you now");
        require(getGameLastStateHash(game) == state.prevHash, "DxGame: hash not right");
    }

    function _setPlayers(
        Game storage game,
        address _challenger,
        address _defender
    ) private validDefender(game, _defender) {
        game.players[0] = _challenger;
        game.players[1] = _defender;
    }

    function _updateDeadlines(
        Game storage game
    ) private {
        game.nextMoveDeadline = block.number + game.MAX_BLOCKS_PER_MOVE;
    }

    function _pushState(
        Game storage game,
        State memory state
    ) private beforeDeadline(game) validNewState(game, state) {
        game.states.push(state);
        _updateDeadlines(game);

        emit UpdateStateEvent(
            game.id,
            game.round,
            game.states.length,
            state.player,
            getGameOpponent(game, state.player),
            game.nextMoveDeadline
        );
    }

    function _announceWinningGame(
        Game storage game,
        address winner,
        address announcer
    ) private {
        game.winner = winner;
        emit WinningEvent(game.id, game.round, winner, announcer);
    }

    function _resetGame(
        Game storage game,
        address player
    ) private {
        delete game.players;
        delete game.states;
        game.nextMoveDeadline = 0;
        emit ResetEvent(game.id, game.round, player);
    }

    function _startGame(
        Game storage game,
        State memory state
    ) private notStarted(game) {
        require(game.MAX_BLOCKS_PER_MOVE != 0, "DxGame: configure your game first please");

        address _defender = getGameDefender(game);
        require(state.player != _defender, "DxGame: you are so ducking boring");

        game.round++;
        _setPlayers(game, state.player, _defender);
        _pushState(game, state);
        emit StartEvent(game.id, game.round, state.player, _defender);
    }
}
