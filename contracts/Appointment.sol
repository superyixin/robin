//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./AppointmentStorage.sol";

interface IGuildNFT {
    function mint(address to, uint256 level, uint256 region) external returns (uint256);
}

contract Appointment is 
    Initializable,
    UUPSUpgradeable,
    AppointmentStorageV1,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable {

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        newImplementation;
        require(msg.sender == owner(), "no auth");
    }

    function __Appointment_init() internal {
    }

    function initialize() public payable initializer {
        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        __Appointment_init();
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 PUBLIC FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////


    /// @notice appoint appoint an activtiy, the msg.sender should approve first
    /// @param idx the proposal number
    function appoint(uint256 idx) payable public nonReentrant {
        require(idx < proposalCount, "no activity found");

        AppointActivity storage activity = proposals[idx];
        require(activity.paused == false, "activity paused");
        require(block.timestamp < activity.endTs, "activity end");
        require(block.timestamp > activity.startTs, "activity not start");
        require(appointUsers[idx][msg.sender] == 0, "user has already appoint");

        if (activity.token == address(0x0)) {
            require(msg.value == activity.amount, "not enough ETH");
        } else {
            IERC20(activity.token).transferFrom(msg.sender, address(this), activity.amount);
        }

        activity.users += 1;
        appointUsers[idx][msg.sender] = 1;

        emit AppointEvent(idx, msg.sender, activity.amount);
    }

    /// @notice reclaim if not chosen, the user reclaim back the money
    /// @param idx the proposal number
    function reclaim(uint256 idx) public nonReentrant {
        require(idx < proposalCount, "no activity found");
        AppointActivity storage activity = proposals[idx];

        require(activity.paused == false, "activity paused");
        require(block.timestamp > activity.reclaimTs, "activity not reach reclaim time");
        require(appointUsers[idx][msg.sender] == 1, "invalid user status");

        if (activity.token == address(0x0)) {
            // bool sent =  payable(msg.sender).send(activity.amount);
            (bool success,) = msg.sender.call{value: activity.amount}("");
            require(success, "Failed to send Ether");
        } else {
            IERC20(activity.token).transfer(msg.sender, activity.amount);
        }
        appointUsers[idx][msg.sender] = 3;

        emit ReclaimEvent(idx, msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////
    ///                 ADMIN FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice createActivity create activity
    /// @param token appoint token
    /// @param amount appoint token amount
    /// @param startTs activity start timestamp, in second
    /// @param endTs activity end timestamp, in second
    /// @param reclaimTs activity reclaim timestamp, in second
    function createActivity(address token,
        uint256 amount,
        uint256 startTs,
        uint256 endTs,
        uint256 reclaimTs) public onlyOwner returns (uint256) {
        require(startTs > block.timestamp, "start ts should great than block.timestamp");
        require(endTs > startTs + 3600, "end ts should great than start ts + 3600");
        require(reclaimTs >= endTs, "reclaimTs should great than end ts");

        uint256 idx = proposalCount;
        proposalCount ++;

        proposals.push(AppointActivity({
            token: token,
            amount: amount,
            startTs: startTs,
            endTs: endTs,
            reclaimTs: reclaimTs,
            users: 0,
            paused: false
        }));

        emit ActivityCreated(idx, token, amount, startTs, endTs, reclaimTs);
        return idx;
    }

    /// @notice modifyActivity modify activity
    /// @param idx activity index
    /// @param token appoint token
    /// @param amount appoint token amount
    /// @param startTs activity start timestamp, in second
    /// @param endTs activity end timestamp, in second
    /// @param reclaimTs activity reclaim timestamp, in second
    function modifyActivity(uint256 idx,
        address token,
        uint256 amount,
        uint256 startTs,
        uint256 endTs,
        uint256 reclaimTs) public onlyOwner {
        require(idx < proposalCount, "no activity found");

        AppointActivity storage activity = proposals[idx];
        require(activity.startTs > block.timestamp, "activity has started");
        require(startTs > block.timestamp, "start ts should great than block.timestamp");
        require(endTs > startTs + 3600, "end ts should great than start ts + 3600");
        require(reclaimTs >= endTs, "reclaimTs should great than end ts");

        activity.token = token;
        activity.amount = amount;
        activity.startTs = startTs;
        activity.endTs = endTs;
        activity.reclaimTs = reclaimTs;

        emit ActivityModify(idx, token, amount, startTs, endTs, reclaimTs);
    }

    /// @notice modifyActivityTime modify activity time
    /// @param idx activity index
    /// @param startTs activity start timestamp, in second
    /// @param endTs activity end timestamp, in second
    /// @param reclaimTs activity reclaim timestamp, in second
    function modifyActivityTime(uint256 idx,
        uint256 startTs,
        uint256 endTs,
        uint256 reclaimTs) public onlyOwner {
        require(idx < proposalCount, "no activity found");

        require(endTs > block.timestamp, "end ts should great than now");
        require(reclaimTs >= endTs, "reclaimTs should great than end ts");

        AppointActivity storage activity = proposals[idx];
        if (activity.startTs > block.timestamp) {
            // has not start, we can change start ts
            activity.startTs = startTs;
        }

        activity.endTs = endTs;
        activity.reclaimTs = reclaimTs;

        emit ActivityTsChanged(idx, startTs, endTs, reclaimTs);
    }

    /// @notice setAppointUsers 设置中签用户
    function setAppointUsers(
        uint256 idx,
        address[] calldata users,
        uint[] calldata _levels,
        uint[] calldata _regions
    ) external onlyOwner {
        require(idx < proposalCount, "no activity found");
        require(users.length == _levels.length, "invalid params");
        address token = proposals[idx].token;
        uint256 amt = proposals[idx].amount;
        // require(activity.reclaimTs > block.timestamp, "reclaim ts should great than now");

        for (uint i = 0; i < users.length; i ++) {
            if (appointUsers[idx][users[i]] == 1) {
                appointUsers[idx][users[i]] = 2;
                totalAmt[token] += amt;
                // mint guilt NFT to user
                IGuildNFT(guildNFTAddr).mint(users[i], _levels[i], _regions[i]);
            }
        }
        emit AppointUsersEvent(idx);
    }

    function setGuildNFTAddr(address _addr) external onlyOwner {
        guildNFTAddr = _addr;
    }

    function setActivityStatus(uint256 idx, bool _paused) external onlyOwner {
        require(idx < proposalCount, "no activity found");

        AppointActivity storage activity = proposals[idx];
        activity.paused = _paused;

        emit ActivityStatusEvent(idx, _paused);
    }

    /// @notice withdraw token
    /// @param to withdraw to
    /// @param token the token for withdraw
    /// @param amount the amount to withdraw
    function withdraw(address to, IERC20 token, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = totalAmt[address(token)]; // token.balanceOf(address(this));
        }
        require(amount > 0, "balance is 0");
        require(amount <= totalAmt[address(token)], "not enough");
        totalAmt[address(token)] -= amount;
        token.transfer(to, amount);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice withdraw ETH/BNB
    /// @param to withdraw to
    /// @param amount the amount to withdraw
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = totalAmt[address(0x0)]; // address(this).balance;
        }
        require(amount > 0, "balance is 0");
        require(amount <= totalAmt[address(0)], "not enough");
        totalAmt[address(0)] -= amount;
        // bool sent = to.send(amount);
        (bool sent,) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
