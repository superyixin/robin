//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "./BaseNFT.sol";
import "./GuildNFTStorage.sol";

contract GuildNFT is
    ERC2771ContextUpgradeable,
    BaseNFT,
    GuildNFTStorageV1
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    function initialize() public payable initializer {
        __BaseNFT_init(msg.sender, SIGNING_DOMAIN, SIGNATURE_VERSION,
            "https://guild-nft.robinfi.com/", "GuildNFT", "GuildNFT");
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @notice mint NFT token to msgSender.
    function mint(address to, uint256 level, uint256 region) public returns (uint256) {
        require(msg.sender == owner() ||
            hasRole(MINTER_ROLE, msg.sender) ||
            msg.sender == appointAddr ||
            msg.sender == guildFactoryAddr, "no auth");
        uint256 tokenId = _incTokenId();

        _mint(to, tokenId);
        levels[tokenId] = level;
        regions[tokenId] = region;

        return tokenId;
    }

    /// @notice mintBatch NFT token
    function mintBatch(address[] memory to, uint256[] memory _levels, uint256[] memory _regions) public {
        require(msg.sender == owner() ||
            hasRole(MINTER_ROLE, msg.sender), "no auth");
        require(to.length == _levels.length, "invalid params");
        for (uint i = 0; i < to.length; i ++) {
            uint256 tokenId = _incTokenId();
            _mint(to[i], tokenId);
            levels[tokenId] = _levels[i];
            regions[tokenId] = _regions[i];
        }
    }

    /// @notice burn NFT token.
    /// @param tokenId The tokenId for mint.
    function burn(uint256 tokenId) public {
        require (ownerOf(tokenId) == _msgSender(), "no auth");
        _burn(tokenId);
    }

    /// @notice set appointment contract address
    function setAppointAddr(address _addr) external onlyOwner {
        appointAddr = _addr;
    }

    /// @notice set guild factory contract address
    function setGuildFactoryAddr(address _addr) external onlyOwner {
        guildFactoryAddr = _addr;
    }

    /// @notice set guildNFT level
    function setLevel(uint256 _tokenId, uint256 _level) external onlyOwner {
        levels[_tokenId] = _level;
    }

    /// @notice set guildNFT region
    function setRegion(uint256 _tokenId, uint256 _region) external {
        require(msg.sender == owner() ||
            hasRole(MINTER_ROLE, msg.sender), "no auth");
        regions[_tokenId] = _region;
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

    function setAttribute(uint256 tokenId, uint256 property, uint256 val) public {
        require(msg.sender == owner() ||
            hasRole(MINTER_ROLE, msg.sender), "no auth");
        require(_exists(tokenId), "token not exists");
        // require(msg.sender == owner() || msg.sender == admin, "must be owner or admin");

        mapping(uint256 => uint256) storage attr = attributesOf[tokenId];
        attr[property] = val;
    }
}
