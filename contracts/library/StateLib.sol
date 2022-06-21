// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library StateLib {
    struct State {
        bytes32 prevHash;

        address player;
        string message;

        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function getHash(State memory state) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(state.prevHash, state.player, state.message));
    }

    function verifySignature(State memory state) internal pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 stateHash = getHash(state);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, stateHash));
        require(ecrecover(prefixedHash, state.v, state.r, state.s) == state.player, "GuessWhat: signature not right");
    }
}
