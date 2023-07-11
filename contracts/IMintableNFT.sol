// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IMintableNFT {
    function mint(uint256 property, address to, uint256 region) external returns (uint256);
    function mint(uint256 property, address to) external returns (uint256);
    function mint(address to) external returns (uint256);
}
