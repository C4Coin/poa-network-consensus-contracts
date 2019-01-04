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

contract RegistryProxy is Ownable {
    IRegistry registry;

    constructor(IRegistry _registry) public Ownable() {
        registry = _registry;
    }

    function update(address _registry) public onlyOwner {
        registry = IRegistry(_registry);
    }

    function () {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            //let _reg := sload(
            let result := delegatecall(gas, sload(registry_slot), ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
