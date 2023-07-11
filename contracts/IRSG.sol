// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRSG is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;
    function mintStaking(uint256 amount) external;
    function idNFTClaim(address to, uint256 amount) external;
}
