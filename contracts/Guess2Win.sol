// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Guess2Win {
    uint256 constant public max_reveal_time = 1 days;
    uint256 constant public min_freeze_time = 1 hours;

    struct Game {
        address token;
        uint256 amount;
    
        address owner;
        uint256 question;
        uint256 startAt;

        address answerer;
        bool answer;
        uint256 answerAt;

        bool revealedAnswer;

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
        uint256 question,

        uint256 revealTime,
        uint256 freezeTime,
        uint256 expiryTime
    ) public returns (uint256 id) {
        require(amount > 0, "You need to put at least some tokens");
        require(revealTime <= max_reveal_time, "Reveal time must be at most 1 day");
        require(freezeTime >= min_freeze_time, "Freeze time must be at least 1 hour");
        require(expiryTime >= min_freeze_time, "Expiry time must be at least 1 hour");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        Game memory game;

        game.token = token;
        game.amount = amount;
        game.owner = msg.sender;
        game.question = question;
        game.startAt = block.timestamp;

        game.revealTime = revealTime;
        game.freezeTime = freezeTime;
        game.expiryTime = expiryTime;

        games.push(game);
        emit Add(games.length - 1,
            game.owner,
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
        require(game.delisted == false, "Game already delisted");

        game.delisted = true;
        IERC20(token).transfer(msg.sender, amount);
    }

    function renew (uint256 id) external {
        Game storage game = games[id];
        require(msg.sender == game.owner, "Only the owner can renew the game");
        require(game.answerer == address(0), "Cannot renew an answered game");
        require(game.delisted == false, "Cannot renew an delisted game");

        game.startAt = block.timestamp;
    }

    function reply (uint256 id, bool answer) external {
        Game storage game = games[id];

        // TODO: test if this is needed
        require(id < games.length, "Game does not exist");

        require(game.answerer == address(0), "Cannot reply an answered game");
        require(block.timestamp <= game.startAt + game.expiryTime, "Game expired");
        require(game.delisted == false, "Cannot reply an delisted game");

        game.answerer = msg.sender;
        game.answer = answer;
        game.answerAt = block.timestamp;
    }

    function reveal (uint256 id, bool revealedAnswer, string calldata mask) external {
        Game storage game = games[id];
        require(msg.sender == game.owner, "Only the owner can reveal the game");
        require(game.answerer != address(0), "Cannot reveal not answered game");
        require(block.timestamp <= game.answerAt + game.revealTime, "It's too late");
        require(question == uint256(keccak256(abi.encodePacked(revealedAnswer, mask))), "You must provide the original");

        game.revealedAnswer = revealedAnswer;

        if (game.revealedAnswer != game.answer) {
            claim();
        }
    }

    function claim () public {
        game.claimed == true;
    }

    function getWinner (uint256 id) view returns (address) {
        Game storage game = games[id];
        if (block.timestamp > game.startAt + )
    }
}