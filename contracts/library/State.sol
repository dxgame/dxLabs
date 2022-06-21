// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct State {
    bytes32 prevHash;

    address player;
    string message;

    uint8 v;
    bytes32 r;
    bytes32 s;
}

library StateFunctions {
    function getHash(State memory state) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(state.prevHash, state.player, state.message));
    }

    function verifySignature(State memory state) internal pure {
        require(ecrecover(getHash(state), state.v, state.r, state.s) == state.player, "GuessWhat: signature not right");
    }
}
