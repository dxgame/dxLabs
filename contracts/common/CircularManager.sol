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
    }

    struct CircularList {
        uint256 head;
        uint256 idCounter;
        mapping (uint256 => CircularNode) nodes;
    }

    function addCircularNode (CircularList storage list) internal returns (uint256) {
        list.idCounter++;

        uint256 id = list.idCounter;
        list.nodes[id] = CircularNode(id, 0, 0);
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

    function countCircularList(CircularList storage list) internal view returns (uint256) {
        uint256 count = 0;
        uint256 id = list.head;
        while ((id != 0) && (id != list.head)) {
            count++;
            id = list.nodes[id].next;
        }
        return count;
    }

    function _addToCircularList (CircularList storage list, uint256 nodeId) private {
        if (list.head == 0) {
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
