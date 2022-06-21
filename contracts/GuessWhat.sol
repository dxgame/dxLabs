// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./library/Game.sol";

function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}

contract GuessWhat is Ownable, ERC20 {
    Game public game;

    enum Step {
        ONE_ChallengeStarted,
        TWO_DefenderDefended,
        THREE_ChallengerRevealed,
        FOUR_DefenderRevealed
    }

    Step public nextMove = Step.ONE_ChallengeStarted;
    address public lastMover;
    address public nextMover;

    uint constant public MAX_BLOCKS_PER_MOVE = 200;
    uint public nextMoveDeadline;
    uint public noResponseSoClaimWinningDeadline;

    string public revealedRequest;
    string public revealedResponse;

    constructor(uint256 initialSupply) ERC20("GuessWhat", "GSWT") {
        _mint(msg.sender, initialSupply);
        game.winner = _msgSender();
        game.config(true, 100, 4);
    }

    function challenger() public view returns (address) {
        return game.players[0];
    }

    function defender() public view returns (address) {
        return game.players[1];
    }

    function _whoWins() private view returns (address) {
        return isOne(revealedResponse) == isOne(revealedRequest) ? defender : challenger;
    }

    modifier nextMoveIs(Step move) {
        require(Step(game.states.length) == move, "GuessWhat: move not allowed");
        _;
    }

    function challenge(string memory encryptedRequest, address _player, uint8 v, bytes32 r, bytes32 s) private nextMoveIs(Step.ONE_ChallengeStarted) {
        game.start(
            State(0, _player, encryptedRequest, v, r, s),
            game.winner
        );
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

    function claimWinning() external {

    }
}
