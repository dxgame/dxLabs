// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./StateLib.sol";

/*
    step 0: ready to start

    step 1: challenger starts new challenge
    step 2: defender defends

    step 3: challenger reveals
    step 4: defender reveals

    step 5: winner claims winning

    if (the next mover did not move before nextMoveDeadline) {
        the last mover wins
    }

    if (states.length == MAX_STATES) {
        the winner will be determined by cutomized game-specific function whoWins
    }
*/

library GameLib {
    using StateLib for StateLib.State;

    struct Game {
        uint256 id;
        uint256 round;

        uint256 MAX_STATES;
        uint256 MAX_BLOCKS_PER_MOVE;
 
        address winner;
        address[2] players;
        StateLib.State[] states;

        uint256 nextMoveDeadline;
    }

    event ResetEvent(uint256 indexed id, uint256 indexed round, address player);
    event StartEvent(uint256 indexed id, uint256 round, address indexed challenger, address indexed defender);
    event WinningEvent(uint256 indexed id, uint256 indexed round, address indexed winner);
    event UpdateStateEvent(
        uint256 indexed id,
        uint256 round,
        uint256 states,
        address indexed player,
        address indexed nextPlayer,
        uint256 nextMoveDeadline
    );

    function challenger(Game storage game) public view returns (address) {
        return game.players[0];
    }

    function defender(Game storage game) public view returns (address) {
        return game.winner;
    }

    function _isEmpty(Game storage game) private view returns (bool) {
        return game.states.length == 0;
    }

    function _isFull(Game storage game) private view returns (bool) {
        return (game.MAX_STATES != 0) && (game.states.length == game.MAX_STATES);
    }

    function _lastState(Game storage game) private view returns (StateLib.State storage){
        return game.states[game.states.length - 1];
    }

    function _lastPlayer(Game storage game) private view returns (address) {
        return _lastState(game).player;
    }

    function _nextPlayer(Game storage game, address player) private view returns (address) {
        if (game.players[0] == player) return game.players[1];
        if (game.players[1] == player) return game.players[0];
        return address(0);
    }

    function nextPlayer(Game storage game) internal view returns (address) {
        address player = _lastPlayer(game);
        return _nextPlayer(game, player);
    }

    function opponent(Game storage game, address player) internal view returns (address) {
        return _nextPlayer(game, player);
    }

    function _verifyChain(Game storage game, StateLib.State memory state) private view {
        if (_isEmpty(game)) return;

        require(nextPlayer(game) == state.player, "GuessWhat: not for you now");
        require(lastStateHash(game) == state.prevHash, "GuessWhat: hash not right");
    }

    function _noResponse(Game storage game) private view returns (bool) {
        return !_isFull(game)
            && (block.number > game.nextMoveDeadline);
    }

    modifier empty(Game storage game) {
        require(_isEmpty(game), "GuessWhat: game already started");
        _;
    }

    modifier notEmpty(Game storage game) {
        require(!_isEmpty(game), "GuessWhat: game not started");
        _;
    }

    modifier validDefender(Game storage game, address _defender) {
        require(game.winner == address(0) || game.winner == _defender, "GuessWhat: defender should be the winner");
        _;
    }

    modifier beforeDeadline(Game storage game) {
        require(game.nextMoveDeadline == 0 || block.number <= game.nextMoveDeadline, "GuessWhat: you are too late");
        _;
    }

    modifier noResponse(Game storage game, address winner) {
        require(block.number > game.nextMoveDeadline, "GuessWhat: you are too early");
        require(_lastPlayer(game) == winner, "GuessWhat: you not winner");
        _;
    }

    modifier validNewState(Game storage game, StateLib.State memory state) {
        require(!_isFull(game), "GuessWhat: states overflow");
        state.verifySignature();
        _verifyChain(game, state);
        _;
    }

    function _setPlayers(Game storage game, address _challenger, address _defender) private validDefender(game, _defender) {
        game.players[0] = _challenger;
        game.players[1] = _defender;
    }

    function _updateDeadlines(Game storage game) private {
        game.nextMoveDeadline = block.number + game.MAX_BLOCKS_PER_MOVE;
    }

    function _pushState(Game storage game, StateLib.State memory state) private beforeDeadline(game) validNewState(game, state) {
        game.states.push(state);
        _updateDeadlines(game);

        emit UpdateStateEvent(
            game.id,
            game.round,
            game.states.length,
            state.player,
            _nextPlayer(game, state.player),
            game.nextMoveDeadline
        );
    }

    function _announceWinning(Game storage game, address winner) private {
        game.winner = winner;
        emit WinningEvent(game.id, game.round, winner);
    }

    function _reset(Game storage game, address player) private {
        delete game.players;
        delete game.states;
        game.nextMoveDeadline = 0;
        emit ResetEvent(game.id, game.round, player);
    }

    function _claimWinning(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (address) whoWins
    ) private {
        address winner = whoWins(game);
        require(winner == state.player, "GuessWhat: you not winner");
        _announceWinning(game, state.player);
        _reset(game, state.player);
    }

    function _claimWinningBczNoResponse(Game storage game, StateLib.State memory state) private noResponse(game, state.player) {
        _announceWinning(game, state.player);
        _reset(game, state.player);
    }

    function _start(Game storage game, StateLib.State memory state, address _defender) private empty(game) {
        require(game.MAX_BLOCKS_PER_MOVE != 0,
            "GuessWhat: configure your game first please");

        // No winner yet, claim winning directly
        if (defender(game) == address(0)) {
            state.verifySignature();
            _announceWinning(game, state.player);
            return;
        }

        game.round++;
        _setPlayers(game, state.player, _defender);
        _pushState(game, state);
        emit StartEvent(game.id, game.round, state.player, _defender);
    }

    function lastStateHash(Game storage game) internal view returns (bytes32) {
        if (!_isEmpty(game)) {
            return _lastState(game).getHash();
        }
        return blockhash(block.number - 1);
    }

    function config(
        Game storage game,
        uint256 maxStates,
        uint256 maxBlocksPerMove
    ) internal {
        game.MAX_STATES = maxStates;
        game.MAX_BLOCKS_PER_MOVE = maxBlocksPerMove;
    }

    function start(Game storage game, StateLib.State memory state, address _defender) internal {
        if (_isFull(game)) {

            _reset(game, state.player);
        }
        _start(game, state, _defender);
    }

    function play(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (address) whoWins
    ) internal notEmpty(game) {
        _pushState(game, state);

        if (_isFull(game) && whoWins(game) == state.player) {
            _claimWinning(game, state, whoWins);
        }
    }

    function claimWinning(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (address) whoWins
    ) internal {
        state.verifySignature();
        require(lastStateHash(game) == state.prevHash, "GuessWhat: hash not right");

        return _noResponse(game)
            ? _claimWinningBczNoResponse(game, state)
            : _claimWinning(game, state, whoWins);
    }
}
