// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library StateLib {
    struct State {
        bytes32 prevHash;

        address player;
        string message;
    }

    function getHash(State memory state) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(state.prevHash, state.player, state.message));
    }

    function verifySignature(State memory state, uint8 v, bytes32 r, bytes32 s) internal pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 stateHash = getHash(state);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, stateHash));
        require(ecrecover(prefixedHash, v, r, s) == state.player, "GuessWhat: signature not right");
    }

    function checkin(
        bytes32 prevHash, address player, string memory message,
        uint8 v, bytes32 r, bytes32 s
    ) internal pure returns (State memory) {
        State memory state;
        state.prevHash = prevHash;
        state.player = player;
        state.message = message;

        verifySignature(state, v, r, s);

        return state;
    }
}
