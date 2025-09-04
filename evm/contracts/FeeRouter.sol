// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20}  from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiariesUpdated(address indexed platform, address indexed creator);
    event Withdraw(address indexed token, uint256 platformAmount, uint256 creatorAmount);

    error ZeroAddress();
    error NoBalance();

    address public platform;
    address public creator;

    constructor(address _platform, address _creator) Ownable(msg.sender) {
        if (_platform == address(0) || _creator == address(0)) revert ZeroAddress();
        platform = _platform;
        creator  = _creator;
        emit BeneficiariesUpdated(_platform, _creator);
    }

    function setBeneficiaries(address _platform, address _creator) external onlyOwner {
        if (_platform == address(0) || _creator == address(0)) revert ZeroAddress();
        platform = _platform;
        creator  = _creator;
        emit BeneficiariesUpdated(_platform, _creator);
    }

    function withdraw(address token) external {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal == 0) revert NoBalance();
        uint256 half = bal / 2;
        uint256 other = bal - half; // 处理奇数
        IERC20(token).safeTransfer(platform, half);
        IERC20(token).safeTransfer(creator, other);
        emit Withdraw(token, half, other);
    }

    function balanceOf(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}