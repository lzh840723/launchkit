// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title VestingVault
/// @notice Linear vesting vault for an ERC20 with a cliff. The owner funds the vault,
///         and the beneficiary (or owner) can release vested tokens over time.
/// @dev
/// - Time values are unix timestamps in seconds (uint64).
/// - Vested amount is 0 before `start + cliff`; after `start + duration` the entire
///   `totalReceived` is vested; otherwise it vests linearly by `(ts - start)/duration`.
/// - Additional funding increases `totalReceived` and vests pro-rata under the same schedule.
/// - No revoke/stop logic. Uses {ReentrancyGuard} and {SafeERC20}.
contract VestingVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice ERC20 token being vested.
    IERC20  public immutable token;
    /// @notice Recipient of vested tokens.
    address public immutable beneficiary;
    /// @notice Vesting start timestamp (unix seconds).
    uint64  public immutable start;
    /// @notice Total vesting duration in seconds (linear).
    uint64  public immutable duration;
    /// @notice Cliff length in seconds (no vesting before start + cliff).
    uint64  public immutable cliff;

    /// @notice Cumulative amount ever funded into the vault.
    uint256 public totalReceived;
    /// @notice Cumulative amount already released to the beneficiary.
    uint256 public released;

    /// @notice Emitted when the vault receives additional funding.
    /// @param amount Amount pulled from the funder.
    event Funded(uint256 amount);

    /// @notice Emitted when vested tokens are released to the beneficiary.
    /// @param amount Amount sent out.
    event Released(uint256 amount);

    /// @param _token         ERC20 token to vest (non-zero address).
    /// @param _beneficiary   Recipient of vested tokens (non-zero).
    /// @param _start         Vesting start timestamp.
    /// @param _duration      Linear vesting duration (seconds).
    /// @param _cliff         Cliff length (seconds), must be ≤ duration.
    /// @param _initialOwner  Contract owner (authorized to fund).
    constructor(
        IERC20 _token,
        address _beneficiary,
        uint64 _start,
        uint64 _duration,
        uint64 _cliff,
        address _initialOwner
    ) Ownable(_initialOwner) {
        require(address(_token) != address(0), "token=0");
        require(_beneficiary != address(0), "beneficiary=0");
        require(_cliff <= _duration, "cliff>duration");

        token = _token;
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        cliff = _cliff;
    }

    /// @notice Fund the vault by pulling `amount` tokens from the caller (owner).
    /// @dev Requires prior `approve` on the token. CEI pattern + nonReentrant.
    /// @param amount Amount to add to the vesting pool (must be > 0).
    function fund(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "amount=0");
        // Effects
        totalReceived += amount;
        // Interactions
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(amount);
    }

    /// @notice Compute how many tokens are vested at a specific timestamp.
    /// @dev Returns 0 before `start + cliff`. Caps at `totalReceived` after `start + duration`.
    /// @param ts Timestamp to evaluate (unix seconds).
    /// @return Amount vested by `ts`.
    function vestedAmount(uint64 ts) public view returns (uint256) {
        if (ts < start + cliff) return 0;
        if (ts >= start + duration) return totalReceived;
        return (totalReceived * (ts - start)) / duration;
    }

    /// @notice Amount currently releasable to the beneficiary (`vested - released`).
    function releasable() public view returns (uint256) {
        uint256 vested = vestedAmount(uint64(block.timestamp));
        if (vested <= released) return 0;
        return vested - released;
    }

    /// @notice Release vested tokens to the beneficiary.
    /// @dev Callable by the beneficiary or the owner. If `amount` is 0 or exceeds
    ///      the available amount, releases the full `releasable()` value.
    ///      NonReentrant; uses SafeERC20; updates state before transfer.
    /// @param amount Amount to release; pass 0 to release all currently available.
    function release(uint256 amount) external nonReentrant {
        require(msg.sender == beneficiary || msg.sender == owner(), "not allowed");

        uint256 avail = releasable();
        require(avail > 0, "nothing to release");

        uint256 toSend = (amount == 0 || amount > avail) ? avail : amount;

        released += toSend;
        token.safeTransfer(beneficiary, toSend);
        emit Released(toSend);
    }
}
