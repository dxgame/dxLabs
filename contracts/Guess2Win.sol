// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Guess2Win {
    uint256 constant public min_freeze_time = 1 hours;
    uint256 constant public max_reveal_time = 1 days;

    struct Game {
        address token;
        uint256 amount;
    
        address owner;
        bytes32 question;
        uint256 startAt;

        address answerer;
        uint256 answer;

        string revealMessage;

        uint256 revealTime;
        uint256 freezeTime;
        uint256 expiryTime;
        bool delisted;
        bool claimed;
    }

    Game[] games;

    event Add(
        uint256 indexed id,
        address indexed owner,
        uint256 question,
        uint256 startAt
    );

    event Reply(
        uint256 indexed id,
        address indexed answerer,
        uint256 answer
    );

    event Reveal(
        uint256 indexed id,
        uint256 revealMessage
    );

    event Claim(
        uint256 indexed id,
        address indexed winner
    );

    constructor() public {}

    function add () {
        transfer();
    }

    function delist(uint256 id) external {
        require(msg.sender == games[id].owner, "Only the owner can delist the game");
    }

    function renew (uint256 id) {

    }

    function reply (uint256 id) {
        transfer();
    }

    function reveal () {

    }

    function claim () {

    }
}