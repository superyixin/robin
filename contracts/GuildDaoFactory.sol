//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./import.sol";
// import "./GuildDAO.sol";
import "./IMintableNFT.sol";

interface IGuildDAO {
    function initialize() external payable;
    function transferOwnership(address newOwner) external;
}

contract GuildDAOFactory is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable {

    address public guildNFTAddr;
    address public implsAddr;
    address public adminAddr;

    // 创建工会事件
    event GuildDAOCreated (
        address indexed dao
    );

    // constructor(address _guildAddr) {
    //     guildNFTAddr = _guildAddr;
    // }

    // guild can hold guildNFT
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

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        newImplementation;
        require(msg.sender == owner(), "no auth");
    }

    function initialize(address addr, address impls, address admin) public payable initializer {
        __Ownable_init();
        __AccessControl_init();
        // __ReentrancyGuard_init();

        guildNFTAddr = addr;
        implsAddr = impls;
        adminAddr = admin;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}
    
    function setGuildNFTAddr(address _addr) public onlyOwner {
        guildNFTAddr = _addr;
    }

    function setImplsAddr(address _addr) public onlyOwner {
        implsAddr = _addr;
    }

    function setAdminAddr(address _addr) public onlyOwner {
        adminAddr = _addr;
    }

    function createGuildDao() public onlyOwner {
        // uint nftId = IMintableNFT(guildNFTAddr).mint(address(this));
        require(address(guildNFTAddr) != address(0), "guild NFT is 0");
        require(address(implsAddr) != address(0), "impls is 0");
        require(adminAddr != address(0), "admin is 0");
        // AdminUpgradeabilityProxy dao = new AdminUpgradeabilityProxy(implsAddr, adminAddr, new bytes(0));
        // (bool success, ) = address(dao).call(abi.encodeWithSignature("initialize()"));
        // require(success, "initialize failed");
        // AdminUpgradeabilityProxy dao = new AdminUpgradeabilityProxy(implsAddr, adminAddr, new bytes(0x8129fc1c));
        AdminUpgradeabilityProxy dao = new AdminUpgradeabilityProxy(implsAddr, adminAddr, abi.encodeWithSelector(IGuildDAO.initialize.selector));
        // AdminUpgradeabilityProxy dao = new AdminUpgradeabilityProxy(implsAddr, adminAddr, abi.encodeWithSignature("initialize()"));

        IGuildDAO(address(dao)).transferOwnership(msg.sender);
        // IERC721(guildNFTAddr).safeTransferFrom(address(this), address(dao), 0);
        emit GuildDAOCreated(address(dao));
    }
}
