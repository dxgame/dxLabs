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
    event WinningEvent(uint256 indexed id, uint256 round, address indexed winner, address indexed announcer);
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

    function noDefender(Game storage game) public view returns (bool) {
        return defender(game) == address(0);
    }

    function isEmpty(Game storage game) public view returns (bool) {
        return game.states.length == 0;
    }

    function isFull(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns (bool) {
        return isEnd(game)
            || (game.MAX_STATES != 0 && game.states.length == game.MAX_STATES);
    }

    function isHalfway(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns(bool) {
        return !isEmpty(game) && !isFull(game, isEnd);
    }

    function _lastState(Game storage game) private view returns (StateLib.State storage){
        return game.states[game.states.length - 1];
    }

    function _lastPlayer(Game storage game) private view returns (address) {
        return _lastState(game).player;
    }

    function opponent(Game storage game, address player) internal view returns (address) {
        if (game.players[0] == player) return game.players[1];
        if (game.players[1] == player) return game.players[0];
        return address(0);
    }

    function nextPlayer(Game storage game) internal view returns (address) {
        address player = _lastPlayer(game);
        return opponent(game, player);
    }

    function nextMoveIndex(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal beforeDeadline(game) returns (uint256) {
        require(isPlaying(game, isEnd), "GuessWhat: move not allowed");
        return game.states.length;
    }

    function _verifyChain(Game storage game, StateLib.State memory state) private view {
        if (isEmpty(game)) return;

        require(nextPlayer(game) == state.player, "GuessWhat: not for you now");
        require(lastStateHash(game) == state.prevHash, "GuessWhat: hash not right");
    }

    function noResponse(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns (bool) {
        return isHalfway(game, isEnd) && (block.number > game.nextMoveDeadline);
    }

    function isPlaying(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns(bool) {
        return isHalfway(game, isEnd) && (block.number <= game.nextMoveDeadline);
    }

    function notPlaying(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns(bool) {
        return !isPlaying(game, isEnd);
    }

    function stoppedPlaying(
        Game storage game,
        function (Game storage) returns (bool) isEnd
    ) internal returns(bool) {
        return noResponse(game, isEnd) || isFull(game, isEnd);
    }

    modifier empty(Game storage game) {
        require(isEmpty(game), "GuessWhat: game already started");
        _;
    }

    modifier notEmpty(Game storage game) {
        require(!isEmpty(game), "GuessWhat: game not started");
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

    modifier validNewState(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (bool) isEnd    
    ) {
        require(!isFull(game, isEnd), "GuessWhat: states overflow");
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

    function _pushState(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (bool) isEnd
    ) private beforeDeadline(game) validNewState(game, state, isEnd) {
        game.states.push(state);
        _updateDeadlines(game);

        emit UpdateStateEvent(
            game.id,
            game.round,
            game.states.length,
            state.player,
            opponent(game, state.player),
            game.nextMoveDeadline
        );
    }

    function _announceWinning(Game storage game, address winner, address announcer) private {
        game.winner = winner;
        emit WinningEvent(game.id, game.round, winner, announcer);
    }

    function _reset(Game storage game, address player) private {
        delete game.players;
        delete game.states;
        game.nextMoveDeadline = 0;
        emit ResetEvent(game.id, game.round, player);
    }

    function _start(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (bool) isEnd
    ) private empty(game) {
        require(game.MAX_BLOCKS_PER_MOVE != 0, "GuessWhat: configure your game first please");

        address _defender = defender(game);
        require(state.player != _defender, "GuessWhat: you are so ducking boring");

        game.round++;
        _setPlayers(game, state.player, _defender);
        _pushState(game, state, isEnd);
        emit StartEvent(game.id, game.round, state.player, _defender);
    }

    function lastStateHash(Game storage game) internal view returns (bytes32) {
        if (!isEmpty(game)) {
            return _lastState(game).getHash();
        }
        return keccak256(abi.encodePacked(blockhash(block.number - 1), game.id, game.round));
    }

    function start(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (address) whoWins,
        function (Game storage) returns (bool) isEnd
    ) internal {
        require(notPlaying(game, isEnd), "GuessWhat: somebody playing");

        if (stoppedPlaying(game, isEnd)) {
            claimWinning(game, state, whoWins, isEnd);
        }

        noDefender(game)
            ? _announceWinning(game, state.player, state.player)
            : _start(game, state, isEnd);
    }

    function play(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (bool) isEnd
    ) internal {
        require(isPlaying(game, isEnd), "GuessWhat: move not allowed");
        _pushState(game, state, isEnd);
    }

    function claimWinning(
        Game storage game,
        StateLib.State memory state,
        function (Game storage) returns (address) whoWins,
        function (Game storage) returns (bool) isEnd
    ) internal notEmpty(game) {
        require(lastStateHash(game) == state.prevHash, "GuessWhat: hash not right");
        require(stoppedPlaying(game, isEnd), "GuessWhat: somebody playing");

        address winner = noResponse(game, isEnd) ? _lastPlayer(game) : whoWins(game);
        if (winner == address(0)) revert("GuessWhat: nobody won");

        _announceWinning(game, winner, state.player);
        _reset(game, state.player);
    }
}
