//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseNFT.sol";
import "./PropNFTStorage.sol";

contract PropNFT is
    ERC2771ContextUpgradeable,
    BaseNFT,
    PropNFTStorageV1
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    function initialize() public payable initializer {
        __BaseNFT_init(msg.sender, SIGNING_DOMAIN, SIGNATURE_VERSION,
            "https://prop-nft.robinfi.com/", "PropNFT", "PropNFT");
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @notice buyPropNFT buy frag NFT
    /// @param to who owner the NFT
    /// @param propType the level of mint NFT
    function buyPropNFT(address to, uint propType, uint region) public {
        // 验资
        uint256 buyPrice = prices[propType];
        require(buyPrice > 0, "price NOT set");

        // rsgc.transferFrom(_msgSender(), address(this), buyPrice);
        SafeERC20.safeTransferFrom(rsgc, _msgSender(), address(this), buyPrice);

        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        regions[tokenId] = region;
        properties[tokenId] = propType;
    }

    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    function mint(uint256 property, address to) public returns (uint256) {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender) || msg.sender == fragAddress, "no auth");
        require(property != 0, "param property should NOT be 0");
        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        properties[tokenId] = property;

        return tokenId;
    }

    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    /// @param region NFT region
    function mint(uint256 property, address to, uint region) public returns (uint256) {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender) || msg.sender == fragAddress, "no auth");
        require(property != 0, "param property should NOT be 0");
        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        properties[tokenId] = property;
        regions[tokenId] = region;

        return tokenId;
    }

    /// @notice mint NFT token to msgSender.
    /// @param property NFT token property
    /// @param to NFT token owner
    function mintMany(uint256 property, address to, uint256 count) public returns (uint256[] memory) {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender) || msg.sender == fragAddress, "no auth");
        require(property != 0, "param property should NOT be 0");

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
    function mintMany(uint256 property, address to, uint256 count, uint256 region) public returns (uint256[] memory) {
        require(msg.sender == owner() || hasRole(MINTER_ROLE, msg.sender) || msg.sender == fragAddress, "no auth");
        require(property != 0, "param property should NOT be 0");

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
        // require (ownerOf(tokenId) == _msgSender() || hasRole(MINTER_ROLE, msg.sender) || owner() == tx.origin, "no auth");
        require (ownerOf(tokenId) == _msgSender(), "no auth");
        _burn(tokenId);
    }

    /// @notice burnMany burn NFT token.
    /// @param start The tokenId for mint.
    /// @param end The tokenId for mint.
    function burnMany(uint256 start, uint256 end) public {
      for (uint i = start; i < end; i++) {
        burn(i);
      }
    }

    /// @notice setFragNFTAddress set NFT frag address
    /// @param _frag frag NFT address
    function setFragNFTAddress(address _frag) external onlyOwner {
        fragAddress = _frag;
    }

    /// @notice setFragNFTPrice set NFT frag address
    /// @param propType propType
    /// @param price rsgc needed
    function setFragNFTPrice(uint propType, uint price) external onlyOwner {
        prices[propType] = price;
    }

    /// @notice setRsgc set token RSGC address
    /// @param _rsgc rsgc address
    function setRsgc(address _rsgc) external onlyOwner {
        rsgc = IERC20(_rsgc);
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

    function setAttribute(uint256 tokenId, uint256 prop, uint256 val) public onlyOwner {
        require(_exists(tokenId), "token not exists");
        // require(msg.sender == owner() || msg.sender == admin, "must be owner or admin");

        mapping(uint256 => uint256) storage attr = attributesOf[tokenId];
        attr[prop] = val;
    }
}
