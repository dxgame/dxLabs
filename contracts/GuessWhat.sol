// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    step 0: ready for challenge

    step 1: challenger starts new challenge
    step 2: defender defends

    step 3: challenger reveals
    step 4: defender reveals

    step 5: winner claims winning

    if (the next mover did not move before nextMoveDeadline) {
        the current mover can claim winning in noResponseSoClaimWinningDeadline
    }

    if (no body do any shit before noResponseSoClaimWinningDeadline) {
        anyone can start a new challenge
    }
*/

struct State {
    bytes32 prevHash;

    address player;
    string message;

    uint8 v;
    bytes32 r;
    bytes32 s;
}

library StateFunctions {
    function getHash(State memory state) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(state.prevHash, state.player, state.message));
    }

    function verifySignature(State memory state) public pure {
        require(ecrecover(getHash(state), state.v, state.r, state.s) == state.player, "GuessWhat: signature not right");
    }
}


struct Game {
    address winner;
    address[2] players;
    State[] states;

    uint256 nextMoveDeadline;
    uint256 noResponseSoClaimWinningDeadline;
}

using StateFunctions for State;

library GameFunctions {
    uint constant public MAX_BLOCKS_PER_MOVE = 200;
    event WinningEvent(address winner);

    function _isEmpty(Game storage game) private view returns (bool) {
        return game.states.length == 0;
    }

    function _lastState(Game storage game) private view returns (State storage){
        return game.states[game.states.length - 1];
    }

    function _lastPlayer(Game storage game) private view returns (address) {
        return _lastState(game).player;
    }

    function _nextPlayer(Game storage game, State storage state) private view returns (address) {
        if (game.players[0] == state.player) return game.players[1];
        if (game.players[1] == state.player) return game.players[0];
        revert("GuessWhat: player not right");
    }

    function _verifyChain(Game storage game, State memory state) private view {
        if (_isEmpty(game)) return;
    
        State storage lastState = _lastState(game);
        require(_nextPlayer(game, lastState) == state.player, "GuessWhat: not for you now");
        require(lastState.getHash() == state.prevHash, "GuessWhat: hash not right");
    }

    modifier empty(Game storage game) {
        require(_isEmpty(game), "GuessWhat: game already started");
        _;
    }

    modifier validDefender(Game storage game, address defender) {
        require(game.winner == address(0) || game.winner == defender, "GuessWhat: defender should be the winner");
        _;
    }

    modifier beforeDeadline(Game storage game) {
        require(game.nextMoveDeadline == 0 || block.number <= game.nextMoveDeadline, "GuessWhat: you are too late");
        _;
    }

    modifier noResponse(Game storage game, address winner) {
        require(block.number > game.nextMoveDeadline, "GuessWhat: you are too early");
        require(block.number <= game.noResponseSoClaimWinningDeadline, "GuessWhat: you are too late");
        require(_lastPlayer(game) == winner, "GuessWhat: you are not the winner");
        _;
    }

    modifier validState(Game storage game, State memory state) {
        state.verifySignature();
        _verifyChain(game, state);
        _;
    }

    function _setPlayers(Game storage game, address challenger, address defender) private validDefender(game, defender) {
        game.players[0] = challenger;
        game.players[1] = defender;
    }

    function _updateDeadlines(Game storage game) private {
        game.nextMoveDeadline = block.number + MAX_BLOCKS_PER_MOVE;
        game.noResponseSoClaimWinningDeadline = game.nextMoveDeadline + MAX_BLOCKS_PER_MOVE;
    }

    function pushState(Game storage game, State memory state) public beforeDeadline(game) validState(game, state) {
        game.states.push(state);
        _updateDeadlines(game);
    }

    function start(Game storage game, State memory state, address defender) public empty(game) {
        _setPlayers(game, state.player, defender);
        pushState(game, state);
    }

    function _announceWinning(Game storage game, address winner) private {
        game.winner = winner;
        emit WinningEvent(winner);
    }

    function _reset(Game storage game) private {
        delete game.players;
        delete game.states;
        game.nextMoveDeadline = 0;
        game.noResponseSoClaimWinningDeadline = 0;
    }

    function _claimWinningBczNoResponse(Game storage game, State memory state) private noResponse(game, state.player) {
        _announceWinning(game, state.player);
        _reset();
    }

    function claimWinning(Game storage game) public {
        // return _noResponse()
        //     ? _claimWinningBczNoResponse()
        //     : _claimWinning();
    }
}

using GameFunctions for Game;

function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}

contract GuessWhat is Ownable, ERC20 {

    enum Step {
        ONE_ChallengeStarted,
        TWO_DefenderDefended,
        THREE_ChallengerRevealed,
        FOUR_DefenderRevealed,
        FIVE_WinnerClaimed
    }

    address public defender;
    address public challenger;

    Step public nextMove = Step.ONE_ChallengeStarted;
    address public lastMover;
    address public nextMover;

    uint constant public MAX_BLOCKS_PER_MOVE = 200;
    uint public nextMoveDeadline;
    uint public noResponseSoClaimWinningDeadline;

    bytes32 private encryptedRequest;
    bytes32 private encryptedResponse;

    string public revealedRequest;
    string public revealedResponse;

    event UpdateNextMoveEvent(
        Step nextMove,
        address lastMover,
        address nextMover,
        uint nextMoveDeadline,
        uint noResponseSoClaimWinningDeadline
    );
    event ResetNextMoveEvent(address lastMover);

    constructor(uint256 initialSupply) ERC20("GuessWhat", "GSWT") {
        _mint(msg.sender, initialSupply);
    }

    function _whoWins() private view returns (address) {
        return isOne(revealedResponse) == isOne(revealedRequest) ? defender : challenger;
    }

    function _updateNextMove() private {
        lastMover = _msgSender();
        Step currentMove = nextMove;
        nextMove = Step((uint(currentMove) + 1) % 5);

        nextMoveDeadline = block.number + MAX_BLOCKS_PER_MOVE;
        noResponseSoClaimWinningDeadline = nextMoveDeadline + MAX_BLOCKS_PER_MOVE;

        address winner = nextMove == Step.FIVE_WinnerClaimed ? _whoWins() : address(0);

        nextMover = [
            address(0),
            defender,
            challenger,
            defender,
            winner
        ][uint(nextMove)];

        emit UpdateNextMoveEvent(
            nextMove,
            lastMover,
            nextMover,
            nextMoveDeadline,
            noResponseSoClaimWinningDeadline
        );
    }

    function _resetNextMove() private {
        lastMover = _msgSender();

        nextMove = Step.ONE_ChallengeStarted;
        nextMover = address(0);
        nextMoveDeadline = 0;
        noResponseSoClaimWinningDeadline = 0;

        encryptedRequest = 0;
        encryptedResponse = 0;
        revealedRequest = "";
        revealedResponse = "";
    
        emit ResetNextMoveEvent(lastMover);
    }

    modifier nextMoveIs(Step move) {
        require(nextMove == move, "GuessWhat: move not allowed");
        require(nextMover == address(0) || nextMover == _msgSender(), "GuessWhat: you are not allowed");
        require(nextMoveDeadline == 0 || block.number <= nextMoveDeadline, "GuessWhat: you are too late");
        _;
    }

    modifier noResponse() {
        require(lastMover == _msgSender(), "GuessWhat: not the account");
        require(block.number > nextMoveDeadline, "GuessWhat: you are too early");
        require(block.number <= noResponseSoClaimWinningDeadline, "GuessWhat: you are too late");
        _;
    }

    function _noResponse() private view returns (bool) {
        return (block.number > nextMoveDeadline)
            && (block.number <= noResponseSoClaimWinningDeadline);
    }

    function _noDefender() private view returns (bool) {
        return defender == address(0);
    }

    function _lastGameAbandoned() private view returns (bool) {
        return (noResponseSoClaimWinningDeadline != 0)
            && (block.number > noResponseSoClaimWinningDeadline);
    }

    function _announceWinning() private {
        defender = _msgSender();
        emit WinningEvent(defender);
    }

    function challenge(bytes32 _encryptedRequest) external {
        if (_noDefender()) {
            _announceWinning();
            return;
        }

        if (_lastGameAbandoned()) {
            _resetNextMove();
        }
    
        _challenge(_encryptedRequest);
    }

    function _challenge(bytes32 _encryptedRequest) private nextMoveIs(Step.ONE_ChallengeStarted) {
        challenger = _msgSender();
        encryptedRequest = _encryptedRequest;
        _updateNextMove();
    }

    function defend(bytes32 _encryptedResponse) external nextMoveIs(Step.TWO_DefenderDefended) {
        encryptedResponse = _encryptedResponse;
        _updateNextMove();
    }

    function challengerReveal(string memory _revealedRequest) external nextMoveIs(Step.THREE_ChallengerRevealed) {
        bytes32 _encryptedRequest = keccak256(abi.encodePacked(_revealedRequest));
        require(_encryptedRequest == encryptedRequest, "GuessWhat: do not match");
        revealedRequest = _revealedRequest;
        _updateNextMove();
    }

    function defenderReveal(string memory _revealedResponse) external nextMoveIs(Step.FOUR_DefenderRevealed) {
        bytes32 _encryptedResponse = keccak256(abi.encodePacked(_revealedResponse));
        require(_encryptedResponse == encryptedResponse, "GuessWhat: do not match");
        revealedResponse = _revealedResponse;
        _updateNextMove();

        if (nextMover == _msgSender()) {
            _claimWinning();
        }
    }

    function _claimWinning() private nextMoveIs(Step.FIVE_WinnerClaimed) {
        _announceWinning();
        _resetNextMove();
    }

    function _claimWinningBczNoResponse() private noResponse {
        _announceWinning();
        _resetNextMove();
    }

    function claimWinning() external {
        return _noResponse()
            ? _claimWinningBczNoResponse()
            : _claimWinning();
    }
}
