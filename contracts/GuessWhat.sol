// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// The Owner of the contract

contract GuessWhat is Ownable, ERC20 {
    address private _winner;
    address public challenger;

    uint constant public replyOrLoseBlocks = 200;
    uint public defendDue;
    uint public challengerRevealDue;
    uint public defenderRevealDue;

    bytes32 private encryptedRequest;
    bytes32 private encryptedResponse;

    string public revealedRequest;
    string public revealedResponse;

    constructor(uint256 initialSupply) ERC20("GuessWhat", "GSWT") {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(owner(), amount);
    }

    function winner() public view virtual returns (address) {
        return _winner;
    }

    function _win(address _luckyGuy) private {
        _winner = _luckyGuy;
        _setChallenge(0, address(0), 0);
    }

    function _claimTheWinner() private {
        address luckyGuy = isOne(revealedResponse) == isOne(revealedRequest) ? _winner : challenger;
        _win(luckyGuy);
    }

    modifier onlyDefender {
        require(winner() == _msgSender(), "GuessWhat: caller is not the winner");
        _;
    }

    modifier onlyChallenger {
        require(challenger == _msgSender(), "GuessWhat: caller is not the challenger");
        _;
    }

    modifier underChallenge() {
        require(challenger != address(0), "GuessWhat: not under challenge");
        _;
    }

    modifier challengeable() {
        require(challenger == address(0), "GuessWhat: under challenge");
        _;
    }

    modifier defendable() {
        require(block.number <= defendDue, "GuessWhat: overdue");
        _;
    }

    modifier challengerRevealable() {
        require(block.number <= challengerRevealDue, "GuessWhat: overdue");
        _;
    }

    modifier defenderRevealable() {
        require(block.number <= defenderRevealDue, "GuessWhat: overdue");
        _;
    }

    function _setChallenge(uint _defendDue, address _challenger, bytes32 _encryptedRequest) private {
        defendDue = _defendDue;
        challenger = _challenger;
        encryptedRequest = _encryptedRequest;
    }

    function challenge(bytes32 _encryptedRequest) external challengeable {
        if (winner() == address(0)) {
            _win(_msgSender());
            return;
        }
        _setChallenge(block.number + replyOrLoseBlocks, _msgSender(), _encryptedRequest);
    }

    function defend(bytes32 _encryptedResponse) external underChallenge defendable onlyDefender {
        encryptedResponse = _encryptedResponse;
        challengerRevealDue = block.number + replyOrLoseBlocks;
    }

    function challengerReveal(string memory _revealedRequest) external underChallenge challengerRevealable onlyChallenger {
        bytes32 _encryptedRequest = sha256(abi.encodePacked(_revealedRequest));
        require(_encryptedRequest == encryptedRequest, "GuessWhat: do not match");
        revealedRequest = _revealedRequest;

        defenderRevealDue = block.number + replyOrLoseBlocks;
    }

    function defenderReveal(string memory _revealedResponse) external underChallenge defenderRevealable onlyDefender {
        bytes32 _encryptedResponse = sha256(abi.encodePacked(_revealedResponse));
        require(_encryptedResponse == encryptedResponse, "GuessWhat: do not match");
        revealedResponse = _revealedResponse;
        _claimTheWinner();
    }

    // TODO: one player overdue, the opponent could claim winning directly
    // Use game step as index, no next step after next step due, the others could just claim to be the winner
}

// Return first character of a given string.
function isOne(string memory str) pure returns (bool) {
    return bytes(str)[0] == 0x31;
}
