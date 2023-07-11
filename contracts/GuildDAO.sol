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

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./GuildDAOStorage.sol";

contract GuildDAO is
    Initializable,
    UUPSUpgradeable,
    GuildDAOStorageV1,
    AccessControlUpgradeable,
    OwnableUpgradeable {

    uint constant public STAUS_DESTROY = 0x1;

    // 
    // constructor(address _leader) {
        // leader = _leader;
        // guildNFTAddr = IERC721(_guildNFTAddr);
        // guildNFTId = _guildNFTId;
    // }

    modifier guildOpen(){
        require(status == 0, "guild closed");
        _;
    }

    function initialize() public payable initializer {
        __Ownable_init();
        __AccessControl_init();
        // __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        newImplementation;
        require(msg.sender == owner(), "no auth");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

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

    function transferNFT(address to) public guildOpen onlyOwner {
        guildNFTAddr.safeTransferFrom(address(this), to, guildNFTId);
        guildNFTId = 0;
    }

    /// @notice withdraw token
    /// @param to withdraw to
    /// @param token the token for withdraw
    /// @param amount the amount to withdraw
    function withdraw(address to, IERC20 token, uint256 amount) external guildOpen onlyOwner {
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        require(amount > 0, "balance is 0");
        // token.transfer(to, amount);
        SafeERC20.safeTransfer(token, to, amount);
    }

    /// @notice withdraw ETH/BNB
    /// @param to withdraw to
    /// @param amount the amount to withdraw
    function withdrawETH(address payable to, uint256 amount) external guildOpen onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        require(amount > 0, "balance is 0");
        // bool sent = to.send(amount);
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function addMember(address account, uint8 level) public guildOpen onlyOwner {
        members[account] = level;
        memberCount ++;
    }

    function removeMember(address account) public guildOpen onlyOwner {
        members[account] = 0;
        memberCount --;
    }

    function updateMemberLevel(address account, uint8 level) public guildOpen onlyOwner {
        members[account] = level;
    }

    function updateMemberWeight(address account, uint256 val) public guildOpen onlyOwner {
        memberWeights[account] = val;
    }

    // function setGuildLevel(uint256 _level) public guildOpen onlyOwner {
    //     level = _level;
    // }

    function setGuildLiveness(uint256 _liveness) public guildOpen onlyOwner {
        liveness = _liveness;
    }

    function setLeader(address _leader) public guildOpen onlyOwner {
        leader = _leader;
    }

    function setGuildNFT(address _guildNFTAddr, uint _guildNFTId) public guildOpen onlyOwner {
        guildNFTAddr = IERC721(_guildNFTAddr);
        guildNFTId = _guildNFTId;
    }

    function setAll(address _leader, address _guildNFTAddr, uint _guildNFTId) public onlyOwner {
        leader = _leader;
        // level = _level;
        guildNFTAddr = IERC721(_guildNFTAddr);
        guildNFTId = _guildNFTId;
    }

    function setGuildStatus(uint256 _status) public guildOpen onlyOwner {
        // 
        if (_status == STAUS_DESTROY) {
            require(memberCount == 0, "member not clear");
        }
        status = _status;
    }
}
