// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "./RSGCStorage.sol";

contract RSGCToken is
    Initializable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable,
    ERC20PresetMinterPauserUpgradeable,
    OwnableUpgradeable,
    RSGCStorageV1 {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    function RSGCToken_init(address minter) private {
        // _setRoleAdmin(MINTER_ROLE, msg.sender);
        // 部署者为管理员
    }

    function initialize() public payable initializer {
        __Ownable_init();
        __ERC20PresetMinterPauser_init("RSGC", "RSGC");

        RSGCToken_init(msg.sender);
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
}
