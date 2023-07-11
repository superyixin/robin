//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

contract GuildNFTStorageV1 {
  string internal constant SIGNING_DOMAIN = "GuildIDNFT-Voucher";
  string internal constant SIGNATURE_VERSION = "1";

  address public appointAddr;
  address public guildFactoryAddr;
  mapping(uint256 => uint256) public levels;
  
  mapping(uint256 => mapping(uint256 => uint256)) attributesOf; // tokenId -> attributes
  mapping(uint256 => uint256) public regions; // tokenId -> region
}
