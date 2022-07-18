// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./common/HalvingToken.sol";
import "./common/TourneyManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GuessBitToken is TourneyManager, HalvingToken {
    uint256 upperBound;
    Tourney[] tourneys;

    constructor() HalvingToken("GuessBit", "GBT", 1, 50, 1000) {
        upperBound = 1;
    }

    function challenge(
        uint256 tourneyId,
        uint256 challengerSeatId,
        uint256 defenderSeatId,
        string memory encryptedChallenge,
        address player,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        _verifyInput(keccak256(abi.encodePacked(
            tourneyId,
            challengerSeatId,
            defenderSeatId,
            encryptedChallenge
        )), player, v, r, s);

        startTouneyGame(
            tourneys[tourneyId],
            challengerSeatId,
            defenderSeatId,
            encryptedChallenge,
            player
        );
    }

    function defend(
        uint256 tourneyId,
        uint256 gameId,
        uint256 moveIndex,
        uint256 defenderSeatId,
        string memory encryptedDefence,
        address player,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(moveIndex == 1, "GuessWhat: Wrong move index");
        _verifyInput(keccak256(abi.encodePacked(
            tourneyId,
            gameId,
            moveIndex,
            defenderSeatId,
            encryptedDefence
        )), player, v, r, s);

        playTourneyGame(
            tourneys[tourneyId],
            gameId,
            moveIndex,
            defenderSeatId,
            encryptedDefence,
            player
        );
    }

    function revealChallenge(
        uint256 tourneyId,
        uint256 gameId,
        uint256 moveIndex,
        uint256 challengerSeatId,
        string memory revealedChallenge,
        address player,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(moveIndex == 2, "GuessWhat: Wrong move index");
        _verifyInput(keccak256(abi.encodePacked(
            tourneyId,
            gameId,
            moveIndex,
            challengerSeatId,
            revealedChallenge
        )), player, v, r, s);

        require(
            strEqual(tourneys[tourneyId].games[gameId].states[0], hashHex(revealedChallenge)),
            "GuessWhat: do not match"
        );

        playTourneyGame(
            tourneys[tourneyId],
            gameId,
            moveIndex,
            challengerSeatId,
            revealedChallenge,
            player
        );
    }

    function revealDefence(
        uint256 tourneyId,
        uint256 gameId,
        uint256 moveIndex,
        uint256 challengerSeatId,
        string memory revealedDefence,
        address player,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(moveIndex == 3, "GuessWhat: Wrong move index");
        _verifyInput(keccak256(abi.encodePacked(
            tourneyId,
            gameId,
            moveIndex,
            challengerSeatId,
            revealedDefence
        )), player, v, r, s);

        require(
            strEqual(tourneys[tourneyId].games[gameId].states[1], hashHex(revealedDefence)),
            "GuessWhat: do not match"
        );

        playTourneyGame(
            tourneys[tourneyId],
            gameId,
            moveIndex,
            challengerSeatId,
            revealedDefence,
            player
        );
    }

    function whoWinsTheGame(Game storage _game) override internal view returns (uint256) {
        string memory revealedRequest = _game.states[2];
        string memory revealedResponse = _game.states[3];

        uint256 digits = getDigits(upperBound);
        uint256 request = parseIntInFirstDigits(revealedRequest, digits);
        uint256 response = parseIntInFirstDigits(revealedResponse, digits);
        bool challengeIsValid = request <= upperBound;
        bool defendFailed = response != request;

        return (challengeIsValid && defendFailed)
            ? _game.challenger
            : _game.defender;
    }

    function _verifyInput(
        bytes32 inputHash,
        address signer,
        uint8 v, bytes32 r, bytes32 s
    ) private pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, address(this), inputHash));
        require(ecrecover(prefixedHash, v, r, s) == signer, "DxGame: signature not right");
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