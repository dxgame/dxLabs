// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./SeatManager.sol";
import "./GameManager.sol";

abstract contract DeadlineManager is SeatManager, GameManager {
    struct Deadline {
        uint seatId;
        uint gameId;
        uint deadline;
    }
}
