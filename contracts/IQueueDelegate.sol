pragma solidity ^0.4.24;

interface IQueueDelegate {// is IDelegate {
    /* mapping (address => Staker) public stakers; */

    function burnAllForNext () public returns (address);

    function burn (uint256 amount, bytes __data) public;

    function join (uint256 stake_amount, bytes token_id) public;

    function get (address a) view public returns (uint256);

    /* uint256 public length = 0; */
}
