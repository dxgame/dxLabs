// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Guess2Win {
    uint256 constant public max_reveal_time = 1 days;
    uint256 constant public min_freeze_time = 1 hours;

    struct Game {
        address token;
        uint256 amount;
    
        address owner;
        bytes32 question;
        uint256 startAt;

        address answerer;
        bool answer;

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
        uint256 startAt,
        uint256 revealTime,
        uint256 freezeTime,
        uint256 expiryTime
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

    function add (
        address token,
        uint256 amount,
        bytes32 question,

        uint256 revealTime,
        uint256 freezeTime,
        uint256 expiryTime
    ) public returns (uint256 id) {
        require(amount > 0, "You need to put at least some tokens");
        require(revealTime <= max_reveal_time, "Reveal time must be at most 1 day");
        require(freezeTime >= min_freeze_time, "Freeze time must be at least 1 hour");
        require(expiryTime >= min_freeze_time, "Expiry time must be at least 1 hour");

        token.transferFrom(msg.sender, address(this), amount);

        Game game = Game({
            token: token,
            amount: amount,
            owner: msg.sender,
            question: question,
            startAt: block.timestamp,

            revealTime: revealTime,
            freezeTime: freezeTime,
            expiryTime: expiryTime
        });

        games.push(game);
        Add(games.length - 1,
            game.owner,
            game.question,
            game.startAt,
            game.revealTime,
            game.freezeTime,
            game.expiryTime
        );
        return games.length - 1;
    }

    function delist(uint256 id) external {
        Game storage game = games[id];
        require(msg.sender == game.owner, "Only the owner can delist the game");
        require(game.answerer == address(0), "Cannot delist an answered game");
        require(block.timestamp > game.startAt + game.freezeTime, "Cannot delist freezed game");
    }

    function renew (uint256 id) external {
        Game storage game = games[id];
        require(msg.sender == game.owner, "Only the owner can renew the game");
        require(game.answerer == address(0), "Cannot renew an answered game");
        game.startAt = block.timestamp;
    }

    function reply (uint256 id, bool answer) external {
        Game storage game = games[id];
        require(id < games.length, "Game does not exist"); // TODO: test if this is needed
        require(game.answerer == address(0), "Cannot reply an answered game");
        require(block.timestamp > game.startAt + game.expiryTime, "Game expired");
        game.answerer = msg.sender;
        game.answer = answer;
    }

    function reveal (uint256 id, string calldata revealMessage) external {
        Game storage game = games[id];
        require(msg.sender == game.owner, "Only the owner can reveal the game");
        require(game.answerer != address(0), "Cannot reply an answered game");
        game.revealMessage = revealMessage;
    }

    function claim () {
        
    }
}