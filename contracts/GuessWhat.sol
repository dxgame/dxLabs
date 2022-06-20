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

    event WinningEvent(address winner);
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
        require(block.number <= nextMoveDeadline, "GuessWhat: you are too late");
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
        bytes32 _encryptedRequest = sha256(abi.encodePacked(_revealedRequest));
        require(_encryptedRequest == encryptedRequest, "GuessWhat: do not match");
        revealedRequest = _revealedRequest;
        _updateNextMove();
    }

    function defenderReveal(string memory _revealedResponse) external nextMoveIs(Step.FOUR_DefenderRevealed) {
        bytes32 _encryptedResponse = sha256(abi.encodePacked(_revealedResponse));
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

// Return first character of a given string.
function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}
