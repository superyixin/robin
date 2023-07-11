//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PropNFTStorageV1 {
  string internal constant SIGNING_DOMAIN = "PropNFT-Voucher";
  string internal constant SIGNATURE_VERSION = "1";

  mapping(uint256 => uint256) public properties; // tokenId -> prop type

  // frag NFT address
  address public fragAddress;
  
  IERC20 public rsgc;
  mapping(uint256 => uint256) public prices; // prop type -> price
  
  mapping(uint256 => mapping(uint256 => uint256)) attributesOf; // tokenId -> attributes
  mapping(uint256 => uint256) public regions; // tokenId -> region
}
