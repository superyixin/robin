// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

import "./IRSG.sol";
import "./RSGStorage.sol";

contract RSGToken is
    Initializable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable,
    ERC20PresetMinterPauserUpgradeable,
    IRSG,
    OwnableUpgradeable,
    RSGStorageV1 {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) ERC2771ContextUpgradeable(forwarder) {
    }

    function RSGToken_init(address addr) private {
        // 1000_000_000
        maxSupply = 1000000000 * (10 ** 18);
        ieoAddr = addr;
        if (addr != address(0x0)) {
            mint(addr, maxSupply*150/DENOMINATOR);
        }

        bonus.ration = maxSupply*3000/DENOMINATOR;
        staking.ration = maxSupply*1000/DENOMINATOR;
        team.ration = maxSupply*2000/DENOMINATOR;
        ecology.ration = maxSupply*2000/DENOMINATOR;
        advisor.ration = maxSupply*500/DENOMINATOR;
        shares.ration = maxSupply*1350/DENOMINATOR;
        // _setRoleAdmin(MINTER_ROLE, msg.sender);
        // 部署者为管理员
        // _setupRole(DEFAULT_ADMIN_ROLE, minter);
    }

    function initialize(address ieo) public payable initializer {
        __Ownable_init();
        __ERC20PresetMinterPauser_init("RSG", "RSG");

        RSGToken_init(ieo);
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

    /// @notice mint RSG token
    /// @param to to address
    /// @param amount amount to mint
    function mint(address to, uint256 amount) public override(ERC20PresetMinterPauserUpgradeable, IRSG) {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
        require(totalSupply() <= maxSupply, "exceed maxSupply");
    }

    /// @notice allocate RSG token
    function allocate() external {
        _alloc(bonus);

        _alloc(team);
        _alloc(ecology);
        _alloc(advisor);
        _alloc(shares);
    }

    /// @notice idNFTClaim id NFT claim
    /// @param to to address
    /// @param amount amount to transfer
    function idNFTClaim(address to, uint256 amount) public {
        require(msg.sender == idNFTAddress, "msg.sender should be RobinIDNFT contract");
        mint(to, amount);

        bonus.alloced += amount;
        require(bonus.alloced <= bonus.ration, "exceed ration");
    }

    /// @notice TGE enabled
    function tgeEnabled() external onlyOwner {
        require(shares.addr != address(0) && advisor.addr != address(0), "address is zero");

        shares.enabled = true;
        mint(shares.addr, shares.ration/10);
        shares.alloced += shares.ration/10;
        shares.last = block.number;

        advisor.enabled =  true;
        mint(advisor.addr, advisor.ration/10);
        advisor.alloced += shares.ration/10;
        advisor.last = block.number;
    }

    /// @notice setIDNFT set idNFT address
    /// @param _addr RobinNFT contract address
    function setIDNFT(address _addr) external onlyOwner {
        idNFTAddress = _addr;
    }

    function setBonusAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(bonus, enabled, addr, ration, amtPerBlock);
    }

    function setStakingAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(staking, enabled, addr, ration, amtPerBlock);
    }

    function setTeamAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(team, enabled, addr, ration, amtPerBlock);
    }

    function setEcologyAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(ecology, enabled, addr, ration, amtPerBlock);
    }

    function setAdvisorAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(advisor, enabled, addr, ration, amtPerBlock);
    }

    function setsharesAlloc(bool enabled, address addr, uint256 ration, uint256 amtPerBlock) external onlyOwner {
        _updateAlloc(shares, enabled, addr, ration, amtPerBlock);
    }

    /// @notice _updateAlloc update allocation
    /// @param to alloc to modify
    /// @param enabled enable or disable this alloc portation
    /// @param ration max alloc supply
    /// @param amtPerBlock amount allocation per block
    function _updateAlloc(Allocation storage to,
        bool enabled,
        address addr,
        uint256 ration,
        uint256 amtPerBlock) private {
        to.enabled = enabled;
        to.addr = addr;
        if (ration > 0) {
            to.ration = ration;
        }
        to.last = block.number;
        to.amtPerBlock = amtPerBlock;
    }

    function mintStaking(uint256 amount) public {
        require(msg.sender == staking.addr, "msg.sender should bd pool contract");
        if (staking.alloced >= staking.ration) {
            return;
        }
        if (staking.alloced + amount >= staking.ration) {
            amount = staking.ration - staking.alloced;
        }
        if (amount == 0) {
            return;
        }
        mint(staking.addr, amount);
        staking.alloced += amount;
    }

    /// @notice alloc RSG to parts
    function _alloc(Allocation storage to) private {
        uint256 blockNo = block.number;
        if (false == to.enabled) {
            return;
        }
        if (blockNo <= to.last) {
            return;
        }
        if (to.alloced >= to.ration) {
            return;
        }
        if (to.addr == address(0x0)) {
            return;
        }

        uint256 amt = to.amtPerBlock * (blockNo - to.last);
        if (amt + to.alloced > to.ration) {
            amt = to.ration - to.alloced;
        }
        if (amt == 0) {
            return;
        }
        mint(to.addr, amt);
        to.alloced += amt;
        to.last = blockNo;
        return;
    }
}
