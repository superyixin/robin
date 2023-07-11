// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface INFTCreator {
    function getNFTCreator(uint256 tokenId) external view returns (address);
}
