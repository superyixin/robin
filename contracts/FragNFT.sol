//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "./BaseNFT.sol";
import "./FragNFTStorage.sol";

contract FragNFT is
    ERC2771ContextUpgradeable,
    BaseNFT,
    FragNFTStorageV1
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    function initialize() public payable initializer {
        __BaseNFT_init(msg.sender, SIGNING_DOMAIN, SIGNATURE_VERSION,
            "https://frag-nft.robinfi.com/", "FragNFT", "FragNFT");
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    function mint(uint256 property, address to) public returns (uint256) {
        require(property != 0, "param property should NOT be 0");
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender), "no auth");
        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        properties[tokenId] = property;

        return tokenId;
    }
    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    function mintMany(uint256 property, address to, uint256 count) public returns (uint256[] memory) {
        require(property != 0, "param property should NOT be 0");
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender), "no auth");

        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i ++) {
            uint256 tokenId = _incTokenId();

            _mint(to, tokenId);
            properties[tokenId] = property;
            ids[i] = tokenId;
        }

        return ids;
    }
    
    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    /// @param region NFT region
    function mint(uint256 property, address to, uint region) public returns (uint256) {
        require(property != 0, "param property should NOT be 0");
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender), "no auth");
        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        properties[tokenId] = property;
        regions[tokenId] = region;

        return tokenId;
    }
    
    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    /// @param region NFT region
    function mintMany(uint256 property, address to, uint256 count, uint region) public returns (uint256[] memory) {
        require(property != 0, "param property should NOT be 0");
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender), "no auth");

        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i ++) {
            uint256 tokenId = _incTokenId();

            _mint(to, tokenId);
            properties[tokenId] = property;
            ids[i] = tokenId;
            regions[tokenId] = region;
        }

        return ids;
    }

    /// @notice burn NFT token.
    /// @param tokenId The tokenId for mint.
    function burn(uint256 tokenId) public {
        require (ownerOf(tokenId) == _msgSender(), "no auth");
        _burn(tokenId);
    }

    /// @notice synthesize 合成NFT, 由管理员通过元交易调用.
    /// @param from the tokenIds for synthesize
    /// @param tokenAddr token address
    /// @param amt the mint fee of RSGC/USDT
    /// @param propsKey the minted token level
    /// @param region FragNFT region
    function synthesize(uint256[] memory from,
        address tokenAddr,
        uint256 amt,
        uint256 propsKey,
        uint256 region) public returns (uint256) {
        // require(tx.origin == owner(), "tx.origin should be owner");
        require(msg.sender == owner(), "tx.origin should be owner");
        address sender = _msgSender();

        return _synthesize(from, IERC20(tokenAddr), amt, sender, propsKey, region);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 PRIVATE FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    function _synthesize(uint256[] memory from,
        IERC20 tokenAddr,
        uint256 amt,
        address sender,
        uint256 prop,
        uint256 region) private returns (uint256) {
        require(from.length >= 2, "invalid from length");
        if (amt > 0) {
            require(tokenAddr.balanceOf(sender) >= amt, "not enough balance");
            tokenAddr.transferFrom(sender, owner(), amt);
        }

        for (uint i = 0; i < from.length; i ++) {
            burn(from[i]);
        }
        uint256 tokenId = propAddr.mint(prop, sender, region);

        // _transfer(msg.sender, sender, tokenId);
        emit FragNFTSynthesize(tokenId, address(tokenAddr), sender);
        return tokenId;
    }

    function setRSGCToken(address _rsgc) external onlyOwner {
        rsgc = IERC20(_rsgc);
    }

    function setUSDT(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    function setPropNFTAddress(address _prop) external onlyOwner {
        propAddr = IMintableNFT(_prop);
    }

    function getAttribute(uint256 tokenId, uint256 prop) public view returns (uint256) {
        require(_exists(tokenId), "ID nft not exists");
        mapping(uint256 => uint256) storage attr = attributesOf[tokenId];

        return attr[prop];
    }

    function getAttributes(uint256 tokenId, uint256[] memory props) public view returns (uint256[] memory) {
        require(_exists(tokenId), "ID nft not exists");
        mapping(uint256 => uint256) storage attr = attributesOf[tokenId];

        uint256[] memory values = new uint256[](props.length);
        for (uint i = 0; i < props.length; i ++) {
            values[i] = attr[props[i]];
        }

        return values;
    }

    function setAttribute(uint256 tokenId, uint256 property, uint256 val) public onlyOwner {
        require(_exists(tokenId), "token not exists");
        // require(msg.sender == owner() || msg.sender == admin, "must be owner or admin");

        mapping(uint256 => uint256) storage attr = attributesOf[tokenId];
        attr[property] = val;
    }
}
