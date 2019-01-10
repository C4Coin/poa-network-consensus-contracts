pragma solidity ^0.4.24;

/**
 * @title IRegistry
 * @dev An interface for registries.
 */
interface IRegistry {
  function add(address id) public;
  function remove(address id) public;
  function exists(address id) public view returns (bool item);
}
