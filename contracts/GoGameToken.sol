// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface POE {
    function circulatingSupply() external view returns (uint256);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract GameToken {
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
        SeatNFT[] seatsById;

        uint award;
        uint totalBets;
        uint baseAward;
        uint totalAward;

        uint startAt;

        Game[] games;
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

    uint initialAward = 500000000000000000000000;
    uint halvingTourneys = 2100;

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
