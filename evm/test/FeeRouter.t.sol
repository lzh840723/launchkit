// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract FeeRouter is AccessControl {
    // 角色
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    // 受益人
    address public platform;
    address public creator;

    // 费率：万分比（bps）
    uint16 public platformBps = 100; // 1%
    uint16 public creatorBps  = 100; // 1%
    uint16 public constant MAX_TOTAL_BPS = 500; // 上限 5%

    constructor(address _platform, address _creator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FEE_SETTER_ROLE, msg.sender);
        platform = _platform;
        creator  = _creator;
    }

    function setFeeRecipients(address _platform, address _creator)
        external
        onlyRole(FEE_SETTER_ROLE)
    {
        require(_platform != address(0) && _creator != address(0), "zero addr");
        platform = _platform;
        creator  = _creator;
    }

    function setFees(uint16 _platformBps, uint16 _creatorBps)
        external
        onlyRole(FEE_SETTER_ROLE)
    {
        require(_platformBps + _creatorBps <= MAX_TOTAL_BPS, "fee too high");
        platformBps = _platformBps;
        creatorBps  = _creatorBps;
    }

    function totalBps() public view returns (uint16) {
        return platformBps + creatorBps;
    }

    /// @notice 按当前费率对 amount 报价（平台份额, 创作者份额）
    function quote(uint256 amount) external view returns (uint256 p, uint256 c) {
        p = (amount * platformBps) / 10_000;
        c = (amount * creatorBps)  / 10_000;
    }
}
