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


import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import './Lockable.sol';
import './IBurnableERC20.sol';
import './TokenRegistry.sol';


contract BurnableStakeBank is Lockable {
    using SafeMath for uint256;

    struct Checkpoint {
        uint256 at;
        uint256 amount;
    }

    TokenRegistry tokenRegistry;
    Checkpoint[] public stakeHistory;
    Checkpoint[] public burnHistory;
    uint256 minimumStake;

    mapping (address => Checkpoint[]) public stakesFor;
    mapping (address => Checkpoint[]) public burnsFor;

    constructor(address _tokenRegistryAddress, uint256 _minimumStake) public {
        require(_tokenRegistryAddress != 0x0);
        tokenRegistry = TokenRegistry(_tokenRegistryAddress);
        minimumStake = _minimumStake;
    }

    function stake(uint256 amount, bytes data) public {
        stakeFor(msg.sender, amount, data);
    }

    function stakeFor(address user, uint256 amount, bytes __data) public onlyWhenUnlocked {
        require( amount >= minimumStake );

        updateCheckpointAtNow(stakesFor[user], amount, false);
        updateCheckpointAtNow(stakeHistory, amount, false);

        // Convert bytes to bytes32
        bytes32 tokenId = _bytesToBytes32(__data, 0);

        require( tokenRegistry.contains(tokenId));
        IBurnableERC20 token = IBurnableERC20( tokenRegistry.getAddress(tokenId) );

        require(token.transferFrom(user, address(this), amount));
    }

    function burnFor(address user, uint256 burnAmount, bytes __data) public onlyWhenUnlocked onlyOwner {
        require(totalStakedFor(user) >= burnAmount);

        // Convert bytes to bytes32
        bytes32 tokenId = _bytesToBytes32(__data, 0);

        // Burn tokens
        updateCheckpointAtNow(burnsFor[user], burnAmount, false);
        updateCheckpointAtNow(burnHistory, burnAmount, false);

        require( tokenRegistry.contains(tokenId));
        IBurnableERC20 token = IBurnableERC20( tokenRegistry.getAddress(tokenId) );
        token.burn(burnAmount);

        // Remove stake
        updateCheckpointAtNow(stakesFor[user], burnAmount, true);
        updateCheckpointAtNow(stakeHistory, burnAmount, true);
    }

    function unstakeFor(address user, uint256 amount, bytes __data) public {
        require(totalStakedFor(user) >= amount);

        uint256 preStake   = totalStakedFor(user);
        uint256 postStake  = preStake - amount;
        require(postStake >= minimumStake || postStake == 0);

        updateCheckpointAtNow(stakesFor[user], amount, true);
        updateCheckpointAtNow(stakeHistory, amount, true);

        // Convert bytes to bytes32
        bytes32 tokenId = _bytesToBytes32(__data, 0);

        require( tokenRegistry.contains(tokenId));
        IBurnableERC20 token = IBurnableERC20( tokenRegistry.getAddress(tokenId) );
        require(token.transfer(user, amount));
    }

    function totalStakedFor(address addr) public view returns (uint256) {
        Checkpoint[] storage stakes = stakesFor[addr];

        if (stakes.length == 0) {
            return 0;
        }

        return stakes[stakes.length-1].amount;
    }

    function totalStaked() public view returns (uint256) {
        return totalStakedAt(block.number);
    }

    function totalBurned() public view returns (uint256) {
        return totalBurnedAt(block.number);
    }

    function supportsHistory() public pure returns (bool) {
        return true;
    }

    function token() public view returns (address) {
        return address(0);
    }

    function lastStakedFor(address addr) public view returns (uint256) {
        Checkpoint[] storage stakes = stakesFor[addr];

        if (stakes.length == 0) {
            return 0;
        }

        return stakes[stakes.length-1].at;
    }

    function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256) {
        return stakedAt(stakesFor[addr], blockNumber);
    }

    function totalBurnedForAt(address addr, uint256 blockNumber) public view returns (uint256) {
        return stakedAt(burnsFor[addr], blockNumber);
    }


    function totalStakedAt(uint256 blockNumber) public view returns (uint256) {
        return stakedAt(stakeHistory, blockNumber);
    }

    function totalBurnedAt(uint256 blockNumber) public view returns (uint256) {
        return stakedAt(burnHistory, blockNumber);
    }

    function updateCheckpointAtNow(Checkpoint[] storage history, uint256 amount, bool isUnstake) internal {
        uint256 length = history.length;
        if (length == 0) {
            history.push(Checkpoint({at: block.number, amount: amount}));
            return;
        }

        // Create new checkpoint for block containing latest stake amount
        if (history[length-1].at < block.number) {
            history.push(Checkpoint({at: block.number, amount: history[length-1].amount}));
        }

        // Add/sub the difference in stake to new checkpoint
        Checkpoint storage checkpoint = history[length];

        if (isUnstake) {
            checkpoint.amount = checkpoint.amount.sub(amount);
        } else {
            checkpoint.amount = checkpoint.amount.add(amount);
        }
    }

    function stakedAt(Checkpoint[] storage history, uint256 blockNumber) internal view returns (uint256) {
        uint256 length = history.length;

        if (length == 0 || blockNumber < history[0].at) {
            return 0;
        }

        if (blockNumber >= history[length-1].at) {
            return history[length-1].amount;
        }

        uint min = 0;
        uint max = length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (history[mid].at <= blockNumber) {
                min = mid;
            } else {
                max = mid-1;
            }
        }

        return history[min].amount;
    }

    function _bytesToBytes32(bytes b, uint offset) private pure returns (bytes32) {
        require(b.length < 32);
        bytes32 out;

        for (uint i = 0; i < b.length; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
   }
}
