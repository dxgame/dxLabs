// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract StateManager {
    struct State {
        bytes32 prevHash;
        address player;
        string message;
    }

    function getStateHash(
        State memory state
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(state.prevHash, state.player, state.message));
    }

    function stateCheckIn(
        bytes32 prevHash, address player,
        string memory message,
        uint8 v, bytes32 r, bytes32 s
    ) internal pure returns (State memory) {
        State memory state;
        state.prevHash = prevHash;
        state.player = player;
        state.message = message;

        _verifySignature(state, v, r, s);

        return state;
    }

    function _verifySignature(
        State memory state,
        uint8 v, bytes32 r, bytes32 s
    ) private pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 stateHash = getStateHash(state);
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, stateHash));
        require(ecrecover(prefixedHash, v, r, s) == state.player, "DxGame: signature not right");
    }
}
