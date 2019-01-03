/*
Smart-contracts for the C4Coin PoB consensus protocol.
Copyright (C) 2018  tigran@c4coin.org

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../interfaces/IRegistry.sol";


contract TokenRegistry is Ownable, IRegistry {
    mapping (address => bool) public tokens;

    constructor() public Ownable() {
    }

    function exists(address token) public view returns (bool) {
        return tokens[token];
    }

    function add(address token) public onlyOwner {
        tokens[token] = true;
    }

    function remove(address token) public onlyOwner {
        tokens[token] = false;
    }
}
