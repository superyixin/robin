//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GuildDAOStorageV1 {
    uint256 status; // 0: normal; 1: 解散
    uint256 guildNFTId;
    IERC721 guildNFTAddr;

    uint256 memberCount;
    uint256 level;
    uint256 liveness; // 活跃度
    address public leader;
    mapping(address => uint8) public members;  // 会员等级
    mapping(address => uint256) public memberWeights;  // 会员等级
}
