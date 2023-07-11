//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMintableNFT.sol";

contract FragNFTStorageV1 {
  string internal constant SIGNING_DOMAIN = "FragNFT-Voucher";
  string internal constant SIGNATURE_VERSION = "1";

  mapping(uint256 => uint256) properties; // tokenId -> prop type
  IERC20 public rsgc; // address of rsg token
  IMintableNFT public propAddr;

  mapping(uint256 => mapping(uint256 => uint256)) attributesOf; // tokenId -> attributes
  
  event FragNFTSynthesize (
      uint indexed tokenId,
      address token,
      address sender
  );
  IERC20 public usdt; // address of rsg token
  mapping(uint256 => uint256) public regions; // tokenId -> prop type
}
