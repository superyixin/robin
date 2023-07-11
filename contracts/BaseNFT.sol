//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./INFTCreator.sol";

contract BaseNFT is
    Initializable,
    UUPSUpgradeable,
    ERC721URIStorageUpgradeable,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    INFTCreator
{
    string public nftUri;
    uint256 public nextTokenId;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => address) private creators;

    function __BaseNFT_init(
        address minter,
        string memory domain,
        string memory version,
        string memory uri,
        string memory _name,
        string memory _symbol
    ) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minter);
        // _setRoleAdmin(MINTER_ROLE, msg.sender);
        // 部署者为管理员
        nftUri = uri;
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __EIP712_init(domain, version);
        __AccessControl_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        newImplementation;
        require(msg.sender == owner(), "no auth");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// @notice set NFT base URI
    /// @param uri the NFT base URI to set
    function setBaseURI(string calldata uri) external onlyOwner {
        nftUri = uri;
    }

    /// @notice NFT base URI
    function _baseURI() internal view override returns (string memory) {
        return nftUri;
    }

    function _incTokenId() internal returns (uint256) {
        nextTokenId ++;
        uint256 tokenId = nextTokenId;
        return tokenId;
    }

    /// @notice withdraw token
    /// @param to withdraw to
    /// @param token the token for withdraw
    /// @param amount the amount to withdraw
    function withdraw(address to, IERC20 token, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        require(amount > 0, "balance is 0");
        // token.transfer(to, amount);
        SafeERC20.safeTransfer(token, to, amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice withdraw ETH/BNB
    /// @param to withdraw to
    /// @param amount the amount to withdraw
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        require(amount > 0, "balance is 0");
        // bool sent = to.send(amount);
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice getNFTCreator get NFT token creator
    /// @param tokenId NFT tokenId
    /// @return token creator address
    function getNFTCreator(uint256 tokenId) external view returns (address) {
        return creators[tokenId];
    }

    /// @notice setNFTCreator set NFT token creator
    /// @param tokenId NFT tokenId
    /// @param creator the token's creator
    function setNFTCreator(uint256 tokenId, address creator) internal {
        creators[tokenId] = creator;
    }
}
