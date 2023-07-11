//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./INFTCreator.sol";
import "./MarketStorage.sol";

contract Market is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    MarketStorageV1 {
    using SafeMath for uint256;

    uint constant public VERSION = 0x1;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    modifier marketOpened(){
        require(marketIsOpen, "market closed");
        _;
    }

    function Market_init() private {
        // 1000_000_000
        // _setRoleAdmin(MINTER_ROLE, msg.sender);
        // 部署者为管理员
        // _setupRole(DEFAULT_ADMIN_ROLE, minter);
        platformFee = 0;
        licenseFee = 0;
        feeTo = msg.sender;
    }

    function initialize() public payable initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        Market_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        newImplementation;
        require(msg.sender == owner(), "no auth");
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 PUBLIC FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice getNFTCreator get NFT creator, if the contract implement INFTCreator, return creator address; or else return zero address
    function getNFTCreator(address nftContract, uint tokenId) public returns (address) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = nftContract.call(abi.encodeWithSelector(
                    INFTCreator.getNFTCreator.selector,
                    tokenId
                ));
        if ((success) && (returndata.length > 0)) { // Return data is optional
            // solhint-disable-next-line max-line-length
            return abi.decode(returndata, (address));
        }
        return address(0);
    }

    /// @notice onSales
    /// @param nftContract the NFT contract to be sale
    /// @param tokenId the NFT tokenId
    /// @param listToken the NFT price token
    /// @param listPrice the NFT price
    /// @return the sales itemId
    function onSales(
        address nftContract,
        uint256 tokenId,
        address listToken,
        uint256 listPrice) public nonReentrant marketOpened returns (uint256) {
        require(listPrice > 0, "price must great than 0");
        require(listToken != address(0), "price token should be ERC20 token");
        
        address seller = _msgSender();
        IERC721(nftContract).transferFrom(seller, address(this), tokenId);

        address creator = getNFTCreator(nftContract, tokenId);
        return _listItem(nftContract, tokenId, listToken, listPrice, seller, creator);
    }

    /// @notice down sales
    /// @param itemId the itemId to down sales
    /// @param withdraw whether withdraw the NFT to seller address
    function offSales(uint256 itemId, bool withdraw) public nonReentrant marketOpened {
        MarketItem storage item = nftItems[itemId];

        // 判断状态, 否则导致重复下架
        require(item.status == uint256(ItemStatus.ItemOnSale), "not onSale");
        address seller = _msgSender();
        require(seller == item.seller, "not seller");

        if (withdraw) {
            IERC721(item.nftContract).transferFrom(address(this), seller, item.tokenId);
            item.seller = address(0);
        }
        item.status = uint(ItemStatus.ItemOffSale);

        tokenIdToItemId[item.nftContract][item.tokenId] = 0;
        emit MarketItemOffSale(itemId, item.nftContract, item.tokenId);
    }

    /// @notice 修改价格 必须为上架状态
    /// @param itemId item id
    /// @param price new price
    function modifyPrice(uint256 itemId, uint256 price) public nonReentrant marketOpened {
        require(price > 0, "price must great than 0");
        MarketItem storage item = nftItems[itemId];

        require(item.status == uint256(ItemStatus.ItemOnSale), "item is not onSale");
        address seller = _msgSender();
        require(seller == item.seller, "not seller");
        item.listPrice = price;

        emit MarketItemPriceChanged(itemId, price);
    }

    /// @notice 重新上架, 仅当item为下架状态, 且该 NFT 的 owner 为 market 合约
    /// @param itemId item id
    /// @param listToken listToken leave 0 if not changed
    /// @param listPrice leave 0 if not changed
    function reSales(uint256 itemId, address listToken, uint256 listPrice) public nonReentrant marketOpened {
        MarketItem storage item = nftItems[itemId];

        require(item.status == uint256(ItemStatus.ItemOffSale), "not in offSale");
        require(IERC721(item.nftContract).ownerOf(item.tokenId) == address(this), "NFT owner is not market");
        address seller = _msgSender();
        require(seller == item.seller, "not seller");

        if (listToken != address(0)) {
            item.listToken = listToken;
        }
        if (listPrice > 0) {
            item.listPrice = listPrice;
        }
        item.status = uint256(ItemStatus.ItemOnSale);
        emit MarketItemReSale(itemId);
    }

    
    /// @notice buyItemCustody 托管方式购买, 购买后 NFT 下架, 购买费用中心化完成
    /// @param itemId item id
    /// @param withdraw 是否转移 nft 到用户地址
    function buyItemCustody(uint256 itemId, bool withdraw) external {
        // require(tx.origin == owner(), "caller should be owner");
        require(msg.sender == owner(), "caller should be owner");

        address buyer = _msgSender();
        MarketItem storage item = nftItems[itemId];
        require(item.status == uint(ItemStatus.ItemOnSale), "status invalid");
        
        _buyItem(item, buyer, withdraw);
    }

    /// @notice 托管方式购买并重新上架, 购买费用中心化完成
    /// @param itemId 待购买的itemId
    /// @param listToken 上架价格token
    /// @param listPrice 上架价格
    /// @return 新上架的 itemId
    function buyAndResaleItemCustody(uint256 itemId, address listToken, uint256 listPrice) external returns (uint256) {
        // require(tx.origin == owner(), "caller should be owner");
        require(msg.sender == owner(), "caller should be owner");
        MarketItem storage item = nftItems[itemId];

        require(item.status == uint(ItemStatus.ItemOnSale), "status invalid");

        address buyer = _msgSender();
        _buyItem(item, buyer, false);
        return _listItem(item.nftContract, item.tokenId, listToken, listPrice, buyer, item.creator);
    }

    /// @notice buyItem 链上方式购买, 购买费用在合约中转账, 调用前需 approve
    /// @param itemId item id
    /// @param withdraw 是否转移 nft 到用户地址
    function buyItem(uint256 itemId, bool withdraw) external {
        MarketItem storage item = nftItems[itemId];
        address buyer = _msgSender();
        
        require(nftItems[itemId].status == uint(ItemStatus.ItemOnSale), "status invalid");
        
        _chargeItemFee(item,  buyer);
        _buyItem(item, buyer, withdraw);
    }

    /// @notice buyItem 链上方式购买, 并重新上架. 购买费用在合约中转账, 调用前需 approve
    /// @param itemId 待购买的itemId
    /// @param listToken 上架价格token
    /// @param listPrice 上架价格
    /// @return 新上架的 itemId
    function buyAndResaleItem(uint256 itemId, address listToken, uint256 listPrice) external returns (uint256) {
        MarketItem storage item = nftItems[itemId];
        address buyer = _msgSender();

        require(nftItems[itemId].status == uint(ItemStatus.ItemOnSale), "status invalid");
        
        _chargeItemFee(item, buyer);
        _buyItem(item, buyer, false);
        return _listItem(item.nftContract, item.tokenId, listToken, listPrice, buyer, item.creator);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 PRIVATE FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    function _listItem(
        address nftContract,
        uint256 tokenId,
        address listToken,
        uint256 listPrice,
        address seller,
        address creator) private returns (uint256) {
        uint256 itemId = nextItemId;
        nextItemId ++;

        MarketItem storage item = nftItems[itemId];
        item.itemId = itemId;
        item.nftContract = nftContract;
        item.tokenId = tokenId;
        item.creator = creator;
        item.seller = seller;
        item.listToken = listToken;
        item.listPrice = listPrice;
        item.status = uint256(ItemStatus.ItemOnSale);

        tokenIdToItemId[nftContract][tokenId] = itemId;

        emit MarketItemOnSale (
            itemId,
            nftContract,
            tokenId,
            seller,
            creator,
            listToken,
            listPrice
        );
        return itemId;
    }

    function _chargeItemFee(MarketItem storage item, address buyer) private {
        uint256 amt  = item.listPrice;
        address creator = item.creator;
        // 平台费
        if (platformFee > 0 && feeTo != address(0)) {
            uint256 fee = item.listPrice.mul(platformFee).div(DENOMINATOR);
            if (fee > 0) {
                IERC20(item.listToken).transferFrom(buyer, feeTo, fee);
            }
            amt = amt.sub(fee);
        }
        // 版税
        if (licenseFee > 0 && creator != address(0)) {
            uint authorFee = item.listPrice.mul(licenseFee).div(DENOMINATOR);
            if (authorFee > 0) {
                IERC20(item.listToken).transferFrom(buyer, creator, authorFee);
            }
            amt = amt.sub(authorFee); // .add(listingPrice);
        }
        IERC20(item.listToken).transferFrom(buyer, item.seller, amt);
    }

    function _buyItem(
        MarketItem storage item,
        address buyer,
        bool withdraw) private {
        item.status = uint(ItemStatus.ItemSoldOut);
        if (withdraw) {
            IERC721(item.nftContract).transferFrom(address(this), buyer, item.tokenId);
            item.seller = address(0);
        } else {
            item.seller = buyer;
        }
       
        emit MarketItemSold(item.itemId, item.nftContract, item.tokenId, buyer, item.listToken, item.listPrice);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 VIEW FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    // 获取上架状态的 NFT 列表
    function fetchMarketItems(uint256[] calldata itemIds) external view returns (MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](itemIds.length);

        for (uint i = 0; i < itemIds.length; i++) {
            items[i] = nftItems[itemIds[i]];
        }
        return items;
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 ADMIN FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice setMarketStatus set market status
    /// @param status the new status to set
    function setMarketStatus(bool status) public onlyOwner {
        marketIsOpen = status;
    }

    /// @notice set platform fee address
    /// @param to platformm fee address
    function setFeeTo(address to) public onlyOwner {
        feeTo = to;
    }

    /// @notice set platform fee ratio
    /// @param fee platformm fee ratio
    function setPlatformFee(uint256 fee) public onlyOwner {
        require(fee < DENOMINATOR/10, "platform fee too high");
        require(fee + licenseFee < DENOMINATOR, "total fee exceeds");
        platformFee = fee;
    }

    /// @notice set license fee ratio
    /// @param fee license fee ratio
    function setLicenseFee(uint256 fee) public onlyOwner {
        require(fee < DENOMINATOR/10, "license fee too high");
        require(fee + platformFee < DENOMINATOR, "total fee exceeds");
        licenseFee = fee;
    }
}
