// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./library/StateLib.sol";
import "./library/GameLib.sol";

function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}

function hashHex(string memory str) pure returns (string memory) {
    return Strings.toHexString(uint(keccak256(abi.encodePacked(str))));
}

function strEqual(string memory a, string memory b) pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}

contract GuessWhat is Ownable, ERC20 {
    using StateLib for StateLib.State;
    using GameLib for GameLib.Game;

    GameLib.Game public game;

    enum Step {
        ONE_ChallengeStarted,
        TWO_DefenderDefended,
        THREE_ChallengerRevealed,
        FOUR_DefenderRevealed
    }

    constructor(uint256 initialSupply) ERC20("GuessWhat", "GSWT") {
        _mint(msg.sender, initialSupply);
        game.winner = _msgSender();
        game.config(true, 100, 4);
    }

    function challenger() public view returns (address) {
        return game.challenger();
    }

    function defender() public view returns (address) {
        return game.defender();
    }

    function whoWins(GameLib.Game storage _game) internal view returns (address) {
        string memory revealedRequest = _game.states[2].message;
        string memory revealedResponse = _game.states[3].message;
        return isOne(revealedResponse) == isOne(revealedRequest) ? _game.defender() : _game.challenger();
    }

    modifier nextMoveIs(Step move) {
        require(Step(game.states.length) == move, "GuessWhat: move not allowed");
        _;
    }

    function challenge(
        bytes32 prehash, address player, string memory encryptedRequest, uint8 v, bytes32 r, bytes32 s
    ) private nextMoveIs(Step.ONE_ChallengeStarted) {
        game.start(
            StateLib.State(prehash, player, encryptedRequest, v, r, s),
            game.winner
        );
    }

    function defend(
        bytes32 prehash, address player, string memory encryptedResponse, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.TWO_DefenderDefended) {
        game.play(
            StateLib.State(prehash, player, encryptedResponse, v, r, s),
            whoWins
        );
    }

    function challengerReveal(
        bytes32 prehash, address player, string memory revealedRequest, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.THREE_ChallengerRevealed) {
        require(
            strEqual(game.states[0].message, hashHex(revealedRequest)),
            "GuessWhat: do not match"
        );

        game.play(
            StateLib.State(prehash, player, revealedRequest, v, r, s),
            whoWins
        );
    }

    function defenderReveal(
        bytes32 prehash, address player, string memory revealedResponse, uint8 v, bytes32 r, bytes32 s
    ) external nextMoveIs(Step.FOUR_DefenderRevealed) {
        require(
            strEqual(game.states[1].message, hashHex(revealedResponse)),
            "GuessWhat: do not match"
        );

        game.play(
            StateLib.State(prehash, player, revealedResponse, v, r, s),
            whoWins
        );
    }

    function claimWinning(
        bytes32 prehash, address player, string memory message, uint8 v, bytes32 r, bytes32 s
    ) external {
        game.claimWinning(
            StateLib.State(prehash, player, message, v, r, s),
            whoWins
        );
    }
}
