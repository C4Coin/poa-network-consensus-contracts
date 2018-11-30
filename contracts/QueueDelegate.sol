pragma solidity ^0.4.24;

import './IDelegate.sol';
//import '../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol';
import './PoB/BurnableERC20.sol';
import './PoB/BurnableStakeBank.sol';

contract QueueDelegate {// is IDelegate {
    mapping (address => Staker) public stakers;
    //BurnableERC20 token;
    BurnableStakeBank bsb;

    constructor (BurnableStakeBank _bsb) {
        //token = _token;
        bsb   = _bsb;
    }

    // Returns address of staker that was burned for
    function burnAllForNext () public returns (address) {
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

    function join (uint256 stake_amount, bytes token_id) public {
        // Transfer staker funds to delegate account
        // token.transferFrom(msg.sender, this, stake_amount);
        bsb.stakeFor(msg.sender, stake_amount, token_id);

        // Add staker to bstake urn list
        add(msg.sender, stake_amount, token_id);
    }

    /*
    function withdraw (bytes token_id) public {
        //require( stakers[msg.sender].exists == true );

        withdrawSomeFor(msg.sender, stakers[msg.sender].amount, token_id );
    }

    function withdrawSomeFor (address user, uint256 stake_amount, bytes token_id) public {
        //require( stakers[msg.sender].exists == true );
        require( stakers[msg.sender].amount >= stake_amount );

        // Return staker's money
        bsb.unstakeFor(user, stake_amount, token_id);

        // TODO: Should not track stake amount in QD contract since it's already tracked in BSB

        // Subtract amount or remove staker from burn list altogether
        if ( stakers[ msg.sender ].amount <= stake_amount )
            remove( msg.sender );
        else
            stakers[ msg.sender ].amount -= stake_amount; // Make this a safe subtract

        // Decrement
        length -= 1;
    }
    */

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

    uint256 public length = 0;
    address head;
    address tail;

    function add(address _addr, uint256 _amount, bytes _tokenid) private {
        stakers[_addr] = Staker({
            next: head,
            prev: address(0),
            amount: _amount,
            token_id: _tokenid,
            exists: true
        });

        if ( stakers[head].exists )
            stakers[head].prev = _addr;
        else
            tail = _addr;

        head = _addr;
        length += 1;
    }

    // ONLY to be used as a queue (remove tail element of list)
    function remove(address _addr) private {
        address prev_id = stakers[_addr].prev;

        if ( stakers[prev_id].exists ) {
            stakers[prev_id].next = address(0);
            tail = prev_id;
        }


        delete stakers[_addr];
        length -= 1;
    }
}

