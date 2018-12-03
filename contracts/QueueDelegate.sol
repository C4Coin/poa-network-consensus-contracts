pragma solidity ^0.4.24;

import './IQueueDelegate.sol';
//import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol';
import './PoB/BurnableERC20.sol';
import './PoB/BurnableStakeBank.sol';

contract QueueDelegate is IQueueDelegate {
    mapping (address => Staker) stakers;
    //BurnableERC20 token;
    BurnableStakeBank bsb;

    constructor (address _bsbAddress) {
        //token = _token;
        /* bsb   = BurnableStakeBank(_bsbAddress); */
    }

    // Returns address of staker that was burned for
    function burnAllForNext () public returns (address) {
        if (tail == address(0)) return tail;

        address headCpy = tail; // Copy head because it may change after burn
        burn(stakers[headCpy].amount, stakers[headCpy].token_id);
        return headCpy;
    }

    function burn (uint256 amount, bytes __data) public {
        bsb.burnFor(tail, amount, __data); // TODO: specify token name in data

        // If all is burned from staker, remove from queue
        if ( amount >= stakers[tail].amount ) {
            remove(tail);            // Remove current tail node
        }
    }

    function get (address a) view public returns (uint256) {
        return stakers[a].amount;
    }

    //
    // Linked list impl
    //
    struct Staker {
        address next;
        address prev;
        uint256 amount;
        bytes token_id;
        bool exists;
    }

    uint256 length;
    address head;
    address tail;

    // ONLY to be used as a queue (remove tail element of list)
    function remove(address _addr) private {
        address prev_id = stakers[_addr].prev;

        if ( stakers[prev_id].exists ) {
            stakers[prev_id].next = address(0);
            tail = prev_id;
        }
        else {
            tail = address(0);
        }

        delete stakers[_addr];
        length -= 1;
    }
}
