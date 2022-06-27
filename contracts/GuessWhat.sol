// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./common/SingleGameManager.sol";

/*
    step 1: challenger starts new challenge
    step 2: defender defends
    step 3: challenger reveals
    step 4: defender reveals
*/

contract GuessWhat is SingleGameManager {
    enum Step {
        ONE_ChallengeStarted,
        TWO_DefenderDefended,
        THREE_ChallengerRevealed,
        FOUR_DefenderRevealed
    }

    constructor() {
        game.MAX_STATES = 4;
    }

    function challenge(
        bytes32 prehash, address player, string memory encryptedRequest, uint8 v, bytes32 r, bytes32 s
    ) external startable {
        State memory state = stateCheckIn(prehash, player, encryptedRequest, v, r, s);

        startGame(game, state);
    }

    function defend(
        bytes32 prehash, address player, string memory encryptedResponse, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.TWO_DefenderDefended) {
        State memory state = stateCheckIn(prehash, player, encryptedResponse, v, r, s);

        playGame(game, state);
    }

    function revealChallenge(
        bytes32 prehash, address player, string memory revealedRequest, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.THREE_ChallengerRevealed) {
        State memory state = stateCheckIn(prehash, player, revealedRequest, v, r, s);

        require(
            strEqual(game.states[0].message, hashHex(revealedRequest)),
            "GuessBit: do not match"
        );
        playGame(game, state);
    }

    function revealDefend(
        bytes32 prehash, address player, string memory revealedResponse, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.FOUR_DefenderRevealed) {
        State memory state = stateCheckIn(prehash, player, revealedResponse, v, r, s);

        require(
            strEqual(game.states[1].message, hashHex(revealedResponse)),
            "GuessBit: do not match"
        );
        playGame(game, state);
    }

    function whoWins(Game storage _game) override internal view notEmpty(_game) returns (address) {
        if (!isGameFinished(_game)) return address(0);

        string memory revealedRequest = _game.states[2].message;
        string memory revealedResponse = _game.states[3].message;
        return isOne(revealedResponse) == isOne(revealedRequest) ? getGameDefender(_game) : getGameChallenger(game);
    }

    modifier nextMoveIs(Step move) {
        require(Step(getGameNextMoveIndex(game)) == move, "DxGame: move not allowed");
        _;
    }
}

function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}

function hashHex(string memory str) pure returns (string memory) {
    return Strings.toHexString(uint(keccak256(abi.encodePacked(str))));
}

function strEqual(string memory a, string memory b) pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}
