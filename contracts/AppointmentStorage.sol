//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AppointmentStorageV1 {
//   string internal constant SIGNING_DOMAIN = "Appointment-Voucher";
//   string internal constant SIGNATURE_VERSION = "1";
    struct AppointActivity {
        address token;
        uint256 amount;
        uint256 startTs;   // 开始时间 second
        uint256 endTs;     // 结束时间 second
        uint256 reclaimTs; // 未中签用户可以提现时间
        uint256 users;
        bool paused;
    }

    event ActivityCreated (
        uint256 indexed id,
        address token,
        uint256 amount,
        uint256 startTs,   // 开始时间 second
        uint256 endTs,     // 结束时间 second
        uint256 reclaimTs
    );

    event ActivityModify (
        uint256 indexed id,
        address token,
        uint256 amount,
        uint256 startTs,   // 开始时间 second
        uint256 endTs,     // 结束时间 second
        uint256 reclaimTs
    );

    event ActivityTsChanged (
        uint256 indexed id,
        uint256 startTs,   // 开始时间 second
        uint256 endTs,     // 结束时间 second
        uint256 reclaimTs
    );

    uint256 public proposalCount;
    AppointActivity[] public proposals;
    mapping(uint256 => mapping(address => uint8)) public appointUsers; // 预约用户是否中签 1: 已预约; 2: 已中签; 3: 已withdraw

    address public guildNFTAddr;
    mapping(address => uint256) public totalAmt;  // 20230705 可提取金额 = 中签用户累计金额 - 已提取金额

  event ActivityStatusEvent (
      uint256 idx,
      bool paused
  );
    
  event AppointUsersEvent (
      uint256 idx
  );

  event AppointEvent (
      uint256 idx,
      address user,
      uint256 amount
  );

  event ReclaimEvent (
      uint256 idx,
      address user
  );
}
