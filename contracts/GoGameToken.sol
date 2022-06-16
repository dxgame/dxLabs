// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface POE {
    function circulatingSupply() external view returns (uint256);
}

abstract contract GameToken is IERC20 {
    struct SeatNFT {
        address owner;

        bool soulBound;
        bool onSale;
        uint price;
        bool acceptChallengeBeforeTourney;

        uint totalSeatShares;
        mapping(address => uint) seatShares;
    }

    struct Tourney {
        uint id;
        SeatNFT[] seats;
        Game[] games;

        uint award;
        uint totalBets;
        uint baseAward;
        uint totalAward;

        uint startAt;
        uint winnerSeatId;
    }

    struct Game {
        uint startAt;
        uint challengerSeatId;
        uint defenderSeatId;

        uint lastUpdateAt;
        /*
            moves: [
                choose komi by challenger,
                choose side by defender,
                black move,
                white move...
            ]
        */
        string[] moves;
        uint nextMoveSeatId;

        uint endAt;
        uint winnerSeatId;

        uint totalPreGameBets;
        mapping(address => uint) challengerPreGameBets;
        mapping(address => uint) defenderPreGameBets;

        // Only available lastUpdateAt in 5mins or less than 10mins
        uint totalInPlayBets;
        mapping(address => uint) challengerInPlayBets;
        mapping(address => uint) defenderInPlayBets;
    }

    // uint initialAward = 500,000,000,000,000,000,000,000;
    // uint halvingTourneys = 2,100;

    // block as timer & ticker
    // tick > beat > tourney
    // A tick ≡ a block
    // A beat, made of ticks, the game player must show up in a beat or will be marked lose of a game
    // Tick Number ≡ Block Number Since first tourney started (from tick no 0)
    // 

    uint genesisBlockNumber = block.number;
    uint ticksPerTourney = 28800; // About one day on BSC
    uint ticksPerBeat = 200; // About 10 mins on BSC
    uint beatsPerTourney = 144; // 

    uint oneToken = 1_000_000_000_000_000_000;
    uint enrollFee = 1_000_000_000_000_000_000;

    uint initialAward = 500_000_000_000_000_000_000_000;
    uint halvingTourneys = 2100;

    // fee dynamics
    // 2^7 * 2^19; 144/6 -> 19;
    uint beatsToDoubleInOneTourney = 6;
    uint tourneysAdvanceToDouble = 7;

    Tourney[] tourneys;

    function getTickNumber() public view returns (uint) {
        return block.number - genesisBlockNumber;
    }
    function getCurrentTourneyId() public virtual returns (uint) {
        return this.getTickNumber() / ticksPerTourney;
    }
    function getCurrentTourney() internal virtual returns (Tourney storage) {
        return tourneys[getCurrentTourneyId()];
    }

    function getTourneyAward(uint tourneyId) public virtual returns (uint) {
        uint halvingCycle = tourneyId / halvingTourneys;
        return initialAward / (2 ^ halvingCycle);
    }
    function getCurrentTourneyAward() public virtual returns (uint) {
        return getTourneyAward(getCurrentTourneyId());
    }

    function amIEnrolled(uint tourneyId) public view virtual returns (bool) {
        return isEnrolled(msg.sender, tourneyId);
    }

    function getSeats(uint tourneyId) internal view virtual returns (SeatNFT[] storage) {
        Tourney storage tourney = tourneys[tourneyId];
        return tourney.seats;
    }

    function isEnrolled(address player, uint tourneyId) public view virtual returns (bool) {
        SeatNFT[] storage seats = getSeats(tourneyId);
        for(uint i; i < seats.length; i++) {
            if (seats[i].owner == player) {
                return true;
            }
        }
        return false;
    }

    function enroll(uint tourneyId, uint fee) public virtual returns (bool) {
        Tourney storage tourney = tourneys[tourneyId];

        // feeDynamics
        // count dynamics per tourney, first 16, 1
        // count dynamics per address, first 1, ... * 2^(n seats alread - 1)
        // time dynamics per tourney, 7 tourneys advance, 1, ... * 2^(7-n days advance)
        // time dynamics per beats, 

        // uint feeDynamics // encourage people enroll in advance, freeze the tokens in seats

        require(fee >= enrollFee, "Not Enough Fee");
        require(amIEnrolled(tourneyId), "Already Enrolled");

        // TODO: Apply dynamic enrollFee, 1 token for  advance,
        this.transfer(address(this), enrollFee);

        SeatNFT[] storage seats = tourney.seats;
        SeatNFT storage newSeat = seats[seats.length];
        newSeat.owner = msg.sender;

        return true;
    }

    function updateGameState(uint tourneyId, uint gameId) public virtual returns (bool);

    function getGame(uint tourneyId, uint gameId) internal virtual returns (Game storage game) {
        game = tourneys[tourneyId].games[gameId];
    }
    function whoWins(Game storage game) internal virtual returns (uint seatId) {
        // game.moves
    }
}

contract GoGameToken is Context, IERC20, POE, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _circulatingSupply;
    // uint256 private _totalSupply = 2,100,000,000,000,000,000,000,000,000;
    uint256 private _totalSupply = 2100000000000000000000000000;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function circulatingSupply() public view virtual override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _circulatingSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _circulatingSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}