//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

contract MarketStorageV1 {
    uint256 public constant DENOMINATOR = 10000;

    enum ItemStatus {
        ItemInital,
        ItemOnSale,
        ItemSoldOut,
        ItemOffSale
    }

    // 上架
    event MarketItemOnSale (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address creator,
        address listToken,
        uint256 listPrice
    );

    // 卖出
    event MarketItemSold (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        address listToken,
        uint256 listPrice
    );

    // 下架
    event MarketItemOffSale (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    // 价格变动
    event MarketItemReSale (
        uint indexed itemId
    );

    // 价格变动
    event MarketItemPriceChanged (
        uint indexed itemId,
        uint256 newPrice
    );

    uint256 public nextItemId;

    // 上架价格
    // address public listToken;
    // uint256 public listingPrice; // 0.025 ether;
    uint256 public platformFee; // 平台手续费
    uint256 public licenseFee;  // 转售原作者收益比例
    address public feeTo;       // 平台手续费地址

    bool public marketIsOpen;

    struct MarketItem {
        address nftContract;
        uint256 tokenId;
        address seller;
        address creator;
        uint256 itemId;
        address listToken;
        uint256 listPrice;
        uint256 status;
    }

    // itemId -> NFT
    mapping(uint256 => MarketItem) public nftItems;
    // nftContract + tokenId => itemId
    mapping(address => mapping(uint256 => uint256)) public tokenIdToItemId;

}
