//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

import "./IRSG.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RobinNFTStorageV1 {
  string internal constant SIGNING_DOMAIN = "RobinIDNFT-Voucher";
  string internal constant SIGNATURE_VERSION = "1";

  struct NFTAttributes {
      uint32 claimed;
      uint32 times;   // max 5
      uint64 ownedAt; // own time, second 
      uint256 level;   // this for cid
      uint256 region;

      mapping(uint256 => uint256) properties; // property -> count
  }

  // 是否可以领取 RSG
  struct RSGClaim {
      bool enabled;
      uint32 nft;      // 最低多少张 ID NFT 可以 claim
      uint32 colddown; // 冷却时间要求
      uint256 bonus;   // 可以领取多少个 RSG
  }

  struct SynthesizePrice {
    uint256 rsgAmount;
    uint256 rsgcAmount;
    uint256 usdtAmount;
  }

  struct SynthesizeReq {
    uint32 status;
    uint256 level;
    uint256 region;
    uint256 ts;
    uint256 id1;
    uint256 id2;
  }

  // 分母均为 10000
  uint256 public constant DENOMINATOR = 10000;
  IRSG public rsg; // address of rsg token
  IERC20 public rsgc; // address of rsgc token
  IERC20 public usdt;
//   IERC20 public buyToken;
  mapping(uint256 => mapping(address => uint256)) public levelPrices;

  RSGClaim public rsgClaim;
  mapping(uint256 => NFTAttributes) public attributesOf;
  address public admin; // just for test
  mapping(uint256 => SynthesizePrice) public sPrices; // 每个level合成所需要的token数量
  mapping(address => SynthesizeReq) public synthesizing; // 正在合成的

  event SetPriceTokenEvent (
      address indexed token
  );

  event SetLevelPriceEvent (
      uint256 level,
      address token,
      uint256 price
  );

  event SynthesizeEvent (
    address indexed addr,
    uint256 level,
    uint256 id1,
    uint256 id2
  );

  event SynthesizeResult (
    address indexed addr,
    bool result,
    uint256 level,
    uint256 id
  );

  event SetSynthesizePriceEvent (
    uint256 level,
    uint256 rsgAmount,
    uint256 rsgcAmount,
    uint256 usdtAmount
  );
}
