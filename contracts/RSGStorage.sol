//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

contract RSGStorageV1 {
    // maxSupply max supply
    uint256 public constant DENOMINATOR = 10000;
    uint256 public maxSupply;

    // token allocation
    struct Allocation {
        bool enabled;
        address addr;     // address to claim
        uint256 ration;   // bonus & liquidity mint; 3000
        uint256 alloced;  // allocated
        uint256 last;     // last alloced block no
        uint256 amtPerBlock;
    }

    // 1.5%
    address public ieoAddr;    // public offer; 150
    Allocation public bonus;   // public offer; 3000
    Allocation public staking; // staking; 1000, the pool contract
    Allocation public team;    // team; 2000
    Allocation public ecology; // ecology; 2000
    Allocation public advisor; // advisor; 500
    Allocation public shares;  // private shares; 1350

    // RobinIDNFT contract address
    address public idNFTAddress;
}
