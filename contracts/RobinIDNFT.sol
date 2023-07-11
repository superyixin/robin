//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./RobinNFTStorage.sol";
import "./BaseNFT.sol";

// import "hardhat/console.sol";

contract RobinIDNFT is
    ERC2771ContextUpgradeable,
    BaseNFT,
    RobinNFTStorageV1
{
    // bytes32 public constant RobinIDNFT_TYPEHASH =
    //     keccak256(
    //         "NFTVoucher(uint256 tokenId,uint256 minPrice,address creator,address publisher,uint256 ratio,string uri)"
    //     );
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    event BuyID(
        address indexed buyer,
        uint256 tokenId,
        uint level,
        uint region
    );

    function initialize(string memory uri) public payable initializer {
        __BaseNFT_init(msg.sender, SIGNING_DOMAIN, SIGNATURE_VERSION, uri, "RobinIDNFT", "RobinIDNFT");
        admin = msg.sender;
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    modifier validNFToken(uint256 _tokenId) {
        require(_exists(_tokenId), "nft not exists");
        _;
    }

    function getProps(uint256 tokenId, uint256[] memory props) public view returns (uint256[] memory) {
        require(_exists(tokenId), "ID nft not exists");
        NFTAttributes storage attr = attributesOf[tokenId];

        uint256[] memory values = new uint256[](props.length);
        for (uint i = 0; i < props.length; i ++) {
            values[i] = attr.properties[props[i]];
        }

        return values;
    }

    function getProperty(uint256 tokenId, uint256 prop) public view returns (uint256) {
        require(_exists(tokenId), "ID nft not exists");
        NFTAttributes storage attr = attributesOf[tokenId];

        return attr.properties[prop];
    }

    /// @notice buyID buy ID NFT
    /// @param level the level of mint NFT
    /// @param howmany number of NFT to buy
    /// @param region NFT region
    function buyID(
        uint level,
        address buyToken,
        uint howmany,
        uint region
    ) public payable returns (uint256[] memory) {
        // 验资
        require(howmany >= 1, "invalid howmany");
        require(level > 0, "invalid level");
        uint256 buyPrice = levelPrices[level][buyToken];
        require(buyPrice > 0, "price NOT set");
        // require(buyer != address(0), "invalid buyer");
        address buyer =  _msgSender();
        if (buyToken != address(0)) {
            // IERC20(buyToken).transferFrom(_msgSender(), address(this), buyPrice * howmany);
            SafeERC20.safeTransferFrom(IERC20(buyToken), _msgSender(), address(this), buyPrice * howmany);
        } else {
            require(msg.value == buyPrice * howmany, "not enough msg.value to buy");
        }

        uint256[] memory ids = new uint256[](howmany);
        for (uint i = 0; i < howmany; i ++) {
            ids[i] = _buyID(buyer, level, region);
        }
        return ids;
    }

    /// @notice buy NFT ID by admin
    /// @param buyer the address who own the NFT
    /// @param level the level of mint NFT
    /// @param howmany number of NFT to buy
    /// @param region NFT region
    function buyIDAdmin(
        address buyer,
        uint level,
        uint howmany,
        uint region
    ) external returns (uint256[] memory) {
        require(howmany >= 1, "invalid howmany");
        require(msg.sender == owner() || msg.sender == admin || hasRole(MINTER_ROLE, msg.sender), "no auth");
        uint256[] memory ids = new uint256[](howmany);
        for (uint i = 0; i < howmany; i ++) {
            ids[i] = _buyID(buyer, level, region);
        }
        return ids;
    }

    function _buyID(address buyer, uint level, uint region) private returns (uint256) {
        uint256 tokenId = _incTokenId();
        _mint(buyer, tokenId);
        NFTAttributes storage attr = attributesOf[tokenId];
        attr.ownedAt = uint64(block.timestamp);
        attr.level = level;
        attr.times = 5;
        attr.region = region;

        emit BuyID(buyer, tokenId, level, region);
        return tokenId;
    }

    /// @notice claimRSG own ID NFT can claim some RSG token
    /// @param ids NFT tokenIds, validate for claim RSG
    function claimRSG(uint256[] memory ids) public {
        require(rsgClaim.enabled, "not claimable");
        require(ids.length == rsgClaim.nft, "NFTs count NOT equal");

        address owner = _msgSender();

        // uint64 now = uint64(block.timestamp);
        uint64 colddown = uint64(rsgClaim.colddown);
        for (uint i = 0; i < ids.length; i ++) {
            require(ownerOf(ids[i]) == owner, "no auth");
            NFTAttributes storage attr = attributesOf[ids[i]];
            require(attr.claimed == 0, "token has already claimed");
            require(attr.ownedAt > 0, "invalid ownedAt");
            require(block.timestamp - attr.ownedAt >= colddown, "not reach cold down time");
            attr.claimed = 1;
        }

        rsg.idNFTClaim(_msgSender(), rsgClaim.bonus);
    }

    /// @notice burn NFT token.
    /// @param tokenId The tokenId for mint.
    function burn(uint256 tokenId) public {
        require (ownerOf(tokenId) == _msgSender(), "no auth");
        _burn(tokenId);
    }

    /// @notice burnMany burn NFT token.
    /// @param start The tokenId for mint.
    /// @param end The tokenId for mint.
    function burnMany(uint256 start, uint256 end) public {
      for (uint i = start; i < end; i++) {
        require (ownerOf(i) == _msgSender(), "no auth");
        _burn(i);
      }
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 ADMIN FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice set ID NFT property
    /// @param tokenId the tokenId of ID NFT
    /// @param property the property of ID NFT
    /// @param times the property count
    function setProperty(uint256 tokenId, uint256 property, uint256 times) public {
        require(_exists(tokenId), "token not exists");
        // require(msg.sender == owner() || msg.sender == admin, "must be owner or admin");
        require(msg.sender == admin, "must be admin");

        NFTAttributes storage attr = attributesOf[tokenId];
        attr.properties[property] = times;
    }

    /// @notice mint NFT token to msg.sender.
    /// @param level The NFT token level for mint.
    function mint(uint256 level, address to) public returns (uint256) {
        require(msg.sender == owner() 
            || msg.sender == admin 
            || hasRole(MINTER_ROLE, msg.sender), "must be owner or admin");

        uint256 tokenId = _incTokenId();
        
        _mint(to, tokenId);
        attributesOf[tokenId].level = level;
        attributesOf[tokenId].ownedAt = uint64(block.timestamp);
        // 身份卡
        attributesOf[tokenId].times = 5;

        setNFTCreator(tokenId, to);

        return tokenId;
    }

    /// @notice mint NFT token to msg.sender.
    /// @param level The NFT token level for mint.
    /// @param region NFT region
    function mint(uint256 level, address to, uint region) public returns (uint256) {
        require(msg.sender == owner() 
            || msg.sender == admin
            || hasRole(MINTER_ROLE, msg.sender), "must be owner or admin");

        uint256 tokenId = _incTokenId();
        
        _mint(to, tokenId);
        attributesOf[tokenId].level = level;
        attributesOf[tokenId].ownedAt = uint64(block.timestamp);
        // 身份卡
        attributesOf[tokenId].times = 5;
        attributesOf[tokenId].region = region;

        setNFTCreator(tokenId, to);

        return tokenId;
    }

    /// @notice mint NFT token to msg.sender.
    /// @param level The NFT token level for mint.
    /// @param region NFT region
    function mint(uint256 level, address to, uint region, uint howmany) public {
        require(msg.sender == owner() 
            || msg.sender == admin 
            || hasRole(MINTER_ROLE, msg.sender), "must be owner or admin");

        for (uint i = 0; i < howmany; i ++) {
            uint256 tokenId = _incTokenId();
            
            _mint(to, tokenId);
            attributesOf[tokenId].level = level;
            attributesOf[tokenId].ownedAt = uint64(block.timestamp);
            // 身份卡
            attributesOf[tokenId].times = 5;
            attributesOf[tokenId].region = region;

            setNFTCreator(tokenId, to);
        }

        return;
    }
    /// @notice mint NFT token to msg.sender.
    /// @param level The NFT token level for mint
    /// @param propsKey The NFT token properties
    /// @param propsCount the NFT token property count
    function mintWithProps(uint256 level, uint256[] calldata propsKey, uint256[] calldata propsCount) external returns (uint256) {
        require(msg.sender == owner() || msg.sender == admin || hasRole(MINTER_ROLE, msg.sender), "must be owner or admin");
        require(propsKey.length == propsCount.length, "props key/value should equal");

        uint256 tokenId = _incTokenId();
        
        _mint(_msgSender(), tokenId);
        NFTAttributes storage attr = attributesOf[tokenId];
        attr.level = level;
        attr.ownedAt = uint64(block.timestamp);
        for (uint i =  0; i < propsKey.length; i ++) {
            attr.properties[propsKey[i]] = propsCount[i];
        }

        setNFTCreator(tokenId, _msgSender());

        return tokenId;
    }

    /// @notice synthesize 合成NFT, 非托管用户调用
    /// @param id1 the NFT to be synthesize
    /// @param id2 the NFT to be synthesize
    function synthesize(
        uint256 id1,
        uint256 id2
    ) public {
        // 校验将要合成的NFT属于msg.sender
        require(ownerOf(id1) == msg.sender, "no auth");
        require(ownerOf(id2) == msg.sender, "no auth");

        // 同一用户同一时刻只能合成一次
        SynthesizeReq storage req = synthesizing[msg.sender];
        require(req.status == 0, "sender is synthesizing");

        // NFT 还有合成次数
        NFTAttributes storage attr1 = attributesOf[id1];
        NFTAttributes storage attr2 = attributesOf[id2];
        uint256 level = attr1.level;
        require(level == attr2.level, "level NOT equal");
        require(attr1.region == attr2.region, "region NOT equal");
        require(attr1.times > 0, "synthesize times is 0");
        require(attr2.times > 0, "synthesize times is 0");
        attr1.times -= 1;
        attr2.times -= 1;
        SynthesizePrice memory price = sPrices[level];

        if (price.rsgAmount > 0) {
            // IERC20(address(rsg)).transferFrom(msg.sender, address(this), price.rsgAmount);
            SafeERC20.safeTransferFrom(IERC20(address(rsg)), msg.sender, address(this), price.rsgAmount);
        }
        if (price.rsgcAmount > 0) {
            // rsgc.transferFrom(msg.sender, address(this), price.rsgcAmount);
            SafeERC20.safeTransferFrom(rsgc, msg.sender, address(this), price.rsgcAmount);
        }
        if (price.usdtAmount > 0) {
            // usdt.transferFrom(msg.sender, address(this), price.usdtAmount);
            SafeERC20.safeTransferFrom(usdt, msg.sender, address(this), price.rsgcAmount);
        }

        req.status = 1;
        req.level = level;
        req.ts = block.timestamp;
        req.id1 = id1;
        req.id2 = id2;
        req.region = attr1.region;

        emit SynthesizeEvent(msg.sender, level, id1, id2);
    }

    /// @notice setSynthesizeResult 合成结果
    /// @param addr synthesize user address
    /// @param success synthesize result
    function setSynthesizeResult(
        address addr,
        bool success,
        uint256 level
    ) external onlyOwner {
        SynthesizeReq storage req = synthesizing[addr];
        require(req.status == 1, "no synthesize request");
        req.status = 0;
        if (!success) {
            emit SynthesizeResult(addr, false, 0, 0);
            return;
        }
        require(ownerOf(req.id1) == addr, "NFT owner transfered");
        require(ownerOf(req.id2) == addr, "NFT owner transfered");

        // mint new NFT to addr
        uint256 tokenId = mint(level, addr, req.region);
        emit SynthesizeResult(addr, true, level, tokenId);
    }

    // function synthesize(
    //     address sender,
    //     uint256[] memory from,
    //     uint256 rsgAmt,
    //     uint256 rsgcAmt,
    //     uint256 usdtAmt,
    //     uint256 resultLevel,
    //     uint256 region,
    //     uint256[] memory propsKey,
    //     uint256[] memory propsCount) public returns (uint256) {
    //     // address sender = _msgSender();
    //     require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender), "no auth");
    //     Synth memory tmp;
    //     tmp.rsgAmt = rsgAmt;
    //     tmp.rsgcAmt = rsgcAmt;
    //     tmp.usdtAmt = usdtAmt;
    //     tmp.resultLevel = resultLevel;
    //     tmp.region = region;

    //     return _synthesize(from, sender, tmp, propsKey, propsCount);
    // }

    /// @notice set rsgClaimable
    /// @param claimable whether use ID NFT claim RSG Token
    function setRsgClaimable(RSGClaim calldata claimable) external onlyOwner {
        rsgClaim.enabled = claimable.enabled;
        rsgClaim.bonus = claimable.bonus;
        rsgClaim.nft = claimable.nft;
        rsgClaim.colddown = claimable.colddown;
    }

    /// @notice disable RSG claimable
    function disableRsgClaimabale() external onlyOwner {
        rsgClaim.enabled = false;
    }
    /// @notice setPriceToken set NFT price token
    /// @param _token the token for pay ID
    // function setPriceToken(IERC20 _token) external onlyOwner {
    //     buyToken = _token;

    //     emit SetPriceTokenEvent(address(_token));
    // }

    /// @notice setLevelPrice set ID price
    /// @param _level the NFT level to set
    /// @param _token the price token
    /// @param _price the NFT price in _token
    function setLevelPrice(uint256 _level, address _token, uint256 _price) external onlyOwner {
        levelPrices[_level][_token] = _price;

        emit SetLevelPriceEvent(_level, _token, _price);
    }

    /// @notice setSynthesizePrice set synthesize price
    /// @param level the NFT level to synthesize
    /// @param rsgAmt the RSG token amount needed
    /// @param rsgcAmt the RSGC token amount needed
    /// @param usdtAmt the USDT token amount n3eeded
    function setSynthesizePrice(
        uint256 level,
        uint256 rsgAmt,
        uint256 rsgcAmt,
        uint256 usdtAmt) external onlyOwner {
        SynthesizePrice storage price = sPrices[level];

        price.rsgAmount = rsgAmt;
        price.rsgcAmount = rsgcAmt;
        price.usdtAmount = usdtAmt;

        emit SetSynthesizePriceEvent(level, rsgAmt, rsgcAmt, usdtAmt);
    }

    /// @notice setAdmin set admin address
    /// @param _admin the admin address to set
    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /// @notice setRSG set RSG token address
    /// @param _rsg the RSG address to set
    function setRSG(address _rsg) external onlyOwner {
        rsg = IRSG(_rsg);
    }

    /// @notice setRSGC set RSGC token address
    /// @param _rsgc the RSGC address to set
    function setRSGC(address _rsgc) external onlyOwner {
        rsgc = IERC20(_rsgc);
    }

    /// @notice setUSDT set USDT token address
    /// @param _usdt the USDT address to set
    function setUSDT(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 PRIVATE FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    // function _synthesize(uint256[] memory from,
    //     address sender,
    //     Synth memory tmp,
    //     uint256[] memory propsKey,
    //     uint256[] memory propsCount) private returns (uint256) {
    //     require(from.length >= 2, "invalid from length");
    //     require(propsKey.length == propsCount.length, "props key/value should equal");
    //     require(tmp.resultLevel > 0, "result level should great than 0");
    //     // require(rsg.balanceOf(sender) >= tmp.rsgAmt, "not enough RSG");
    //     // require(rsgc.balanceOf(sender) >= tmp.rsgcAmt, "not enough RSGC");
    //     if (tmp.usdtAmt > 0) {
    //         require(address(usdt) != address(0), "usdt not set");
    //         usdt.transferFrom(sender, owner(), tmp.usdtAmt);
    //     }

    //     if (tmp.rsgAmt > 0) {
    //         require(address(rsg) != address(0), "rsg not set");
    //         rsg.transferFrom(sender, owner(), tmp.rsgAmt);
    //     }
    //     if (tmp.rsgcAmt > 0) {
    //         require(address(rsgc) != address(0), "rsgc not set");
    //         rsgc.transferFrom(sender, owner(), tmp.rsgcAmt);
    //     }

    //     for (uint i = 0; i < from.length; i ++) {
    //         // burn(from[i]);
    //         require(ownerOf(from[i]) == sender);
    //         NFTAttributes storage fromAttr = attributesOf[from[i]];
    //         require(fromAttr.times > 0);
    //         fromAttr.times -= 1;
    //     }

    //     uint256 tokenId = mint(tmp.resultLevel, sender, tmp.region);
    //     NFTAttributes storage attr = attributesOf[tokenId];
    //     // require(attr.times > 0, "no synthesize times");
    //     for (uint i =  0; i < propsKey.length; i ++) {
    //         attr.properties[propsKey[i]] = propsCount[i];
    //     }
    //     // attr.times -= 1;
    //     // _transfer(msg.sender, sender, tokenId);
    //     return tokenId;
    // }
}
