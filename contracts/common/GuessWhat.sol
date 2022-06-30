// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./SingleGameManager.sol";

/*
    step 1: challenger starts new challenge
    step 2: defender defends
    step 3: challenger reveals
    step 4: defender reveals
*/

contract GuessWhat is SingleGameManager {
    uint256 upperBound;

    enum Step {
        ONE_ChallengeStarted,
        TWO_DefenderDefended,
        THREE_ChallengerRevealed,
        FOUR_DefenderRevealed
    }

    constructor(uint256 _upperBound) SingleGameManager(4, 100) {
        upperBound = _upperBound;
    }

    function challenge(
        bytes32 prehash,
        address player,
        string memory encryptedRequest,
        uint8 v, bytes32 r, bytes32 s
    ) external startable {
        State memory state = stateCheckIn(prehash, player, encryptedRequest, v, r, s);

        startGame(game, state);
    }

    function defend(
        bytes32 prehash,
        address player,
        string memory encryptedResponse,
        uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.TWO_DefenderDefended) {
        State memory state = stateCheckIn(prehash, player, encryptedResponse, v, r, s);

        playGame(game, state);
    }

    function revealChallenge(
        bytes32 prehash,
        address player,
        string memory revealedRequest,
        uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.THREE_ChallengerRevealed) {
        State memory state = stateCheckIn(prehash, player, revealedRequest, v, r, s);

        require(
            strEqual(game.states[0].message, hashHex(revealedRequest)),
            "GuessBit: do not match"
        );
        playGame(game, state);
    }

    function revealDefend(
        bytes32 prehash,
        address player,
        string memory revealedResponse,
        uint8 v, bytes32 r, bytes32 s
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

        uint256 digits = getDigits(upperBound);
        uint256 request = parseIntInFirstDigits(revealedRequest, digits);
        uint256 response = parseIntInFirstDigits(revealedResponse, digits);
        bool challengeIsValid = request <= upperBound;
        bool defendFailed = response != request;

        return (challengeIsValid && defendFailed)
            ? getGameChallenger(_game)
            : getGameDefender(_game);
    }

    modifier nextMoveIs(Step move) {
        require(Step(getGameNextMoveIndex(game)) == move, "DxGame: move not allowed");
        _;
    }

    function getDigits(uint256  n) private pure returns (uint256 ) {
        if (n <= 9) return 1;
        return getDigits(n / 10) + 1;
    }

    function parseIntInFirstDigits(
        string memory s,
        uint256 digits
    ) private pure returns (uint256) {
        string memory n = substring(s, 0, digits);
        return parseInt(n);
    }

    function parseInt(string memory s) private pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint8 bi = uint8(b[i]);
            if (bi >= 48 && bi <= 57) {
                result = result * 10 + (bi - 48);
            }
        }
        return result;
    }

    function substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function hashHex(string memory str) private pure returns (string memory) {
        return Strings.toHexString(uint(keccak256(abi.encodePacked(str))));
    }

    function strEqual(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
