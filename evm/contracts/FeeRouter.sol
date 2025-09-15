// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable}   from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20}    from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title FeeRouter
/// @notice Splits any ERC20 balance held by this contract 50/50 between a platform and a creator.
/// @dev Anyone can trigger {withdraw}. Owner can update beneficiaries. No ETH handling.
///      Rounding: platform gets floor(bal/2), creator gets the remainder (ensures full drain).
contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Emitted when beneficiaries are updated.
    event BeneficiariesUpdated(address indexed platform, address indexed creator);

    /// @notice Emitted after a withdrawal.
    event Withdraw(address indexed token, uint256 platformAmount, uint256 creatorAmount);

    /// @dev Reverts when a zero address is provided where non-zero is required.
    error ZeroAddress();
    /// @dev Reverts when the token balance is zero on withdraw.
    error NoBalance();

    /// @notice Current platform and creator recipients.
    address public platform;
    address public creator;

    /// @param _platform Platform recipient address (non-zero).
    /// @param _creator  Creator recipient address (non-zero).
    /// @dev Owner is set to deployer via OZ Ownable(initialOwner).
    constructor(address _platform, address _creator) Ownable(msg.sender) {
        if (_platform == address(0) || _creator == address(0)) revert ZeroAddress();
        platform = _platform;
        creator  = _creator;
        emit BeneficiariesUpdated(_platform, _creator);
    }

    /// @notice Update platform and creator recipients.
    /// @dev Only owner. Both addresses must be non-zero.
    function setBeneficiaries(address _platform, address _creator) external onlyOwner {
        if (_platform == address(0) || _creator == address(0)) revert ZeroAddress();
        platform = _platform;
        creator  = _creator;
        emit BeneficiariesUpdated(_platform, _creator);
    }

    /// @notice Split and transfer the entire ERC20 balance held by this contract.
    /// @param token ERC20 token address to withdraw.
    /// @dev Permissionless; useful for bots/cron. Transfers use SafeERC20.
    ///      If you later add state changes here, consider ReentrancyGuard.
    function withdraw(address token) external {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal == 0) revert NoBalance();

        uint256 half  = bal / 2;           // floor
        uint256 other = bal - half;        // remainder to creator (handles odd amounts)

        IERC20(token).safeTransfer(platform, half);
        IERC20(token).safeTransfer(creator,  other);

        emit Withdraw(token, half, other);
    }

    /// @notice Read the ERC20 balance held by this contract.
    function balanceOf(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
