// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract SeatManager {
    struct Seat {
        address player;
        uint nextMoveDeadline;
        uint price;
    }

    function transferSeat(Seat storage seat, address _to) internal {
        seat.player = _to;
    }

    function extendDeadline(Seat storage seat, uint256 _deadline) internal {
        seat.nextMoveDeadline = _deadline;
    }

    function updatePrice(Seat storage seat, uint256 _price) internal {
        seat.price = _price;
    }

    function isSeatDead(Seat memory seat) internal view returns (bool) {
        return seat.nextMoveDeadline < block.number;
    }

    function isSeatAlive(Seat memory seat) internal view returns (bool) {
        return !isSeatDead(seat);
    }

    function getAliveSeats(Seat[] storage seats) internal view returns (Seat[] memory aliveSeats) {
        for (uint i = 0; i < seats.length; i++) {
            if (seats[i].nextMoveDeadline >= block.number) {
                aliveSeats[aliveSeats.length] = seats[i];
            }
        }
    }

    function getDeadSeats(Seat[] storage seats) internal view returns (Seat[] memory deadSeats) {
        for (uint i = 0; i < seats.length; i++) {
            if (seats[i].nextMoveDeadline < block.number) {
                deadSeats[deadSeats.length] = seats[i];
            }
        }
    }

    function getAliveSeatsCount(Seat[] storage seats) internal view returns (uint count) {
        uint aliveSeatsCount = 0;
        for (uint i = 0; i < seats.length; i++) {
            if (seats[i].nextMoveDeadline >= block.number) {
                aliveSeatsCount++;
            }
        }
        return aliveSeatsCount;
    }

    function getDeadSeatsCount(Seat[] storage seats) internal view returns (uint count) {
        uint deadSeatsCount = 0;
        for (uint i = 0; i < seats.length; i++) {
            if (seats[i].nextMoveDeadline < block.number) {
                deadSeatsCount++;
            }
        }
        return deadSeatsCount;
    }

    function getSeat(Seat[] storage seats, address player) internal view returns (Seat memory seat) {
        for (uint i = 0; i < seats.length; i++) {
            if (seats[i].player == player) {
                return seats[i];
            }
        }
    }
}
