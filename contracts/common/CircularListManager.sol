// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*
    idCounter
        1, 2, 3, 4, 5...
        No node at index of 0
        Id 0 is reserved for null
*/

contract CircularManager {
    struct CircularNode {
        uint256 id;
        uint256 prev;
        uint256 next;
        address data;
    }

    struct CircularList {
        uint256 head;
        uint256 idCounter;
        mapping (uint256 => CircularNode) nodes;
    }

    function addCircularNode (CircularList storage list, address data) internal returns (uint256) {
        list.idCounter++;

        uint256 id = list.idCounter;
        list.nodes[id] = CircularNode(id, 0, 0, data);
        _addToCircularList(list, id);

        return id;
    }

    function removeCircularNode (CircularList storage list, uint256 id) internal {
        CircularNode storage node = list.nodes[id];
        if (list.head == id) {
            list.head = node.next;
        }
        if (node.next != 0) {
            _connectCircularNodes(list, node.prev, node.next);
        }
        delete list.nodes[id];
    }

    function circularListIsEmpty(CircularList storage list) internal view returns (bool) {
        return list.head == 0;
    }

    function circularListIsSingle(CircularList storage list) internal view returns (bool) {
        return !circularListIsEmpty(list) && list.nodes[list.head].next == 0;
    }

    function circularListIsCouple(CircularList storage list) internal view returns (bool) {
        return !circularListIsEmpty(list)
            && !circularListIsSingle(list)
            && list.nodes[list.head].next == list.nodes[list.head].prev;
    }

    function _addToCircularList (CircularList storage list, uint256 nodeId) private {
        if (circularListIsEmpty(list)) {
            list.nodes[nodeId].next = 0;
            list.nodes[nodeId].prev = 0;
            list.head = nodeId;
        } else {
            _connectCircularNodes(list, nodeId, list.head);
            _connectCircularNodes(list, list.nodes[list.head].prev, nodeId);
        }
    }

    function _connectCircularNodes(CircularList storage list, uint256 prevId, uint256 nextId) private {
        require(prevId != 0 && nextId != 0, "prevId and nextId must be non-zero");
        list.nodes[prevId].next = nextId;
        list.nodes[nextId].prev = prevId;
    }
}
