// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TaxedERC20 (OZ v5-ready)
/// @notice ERC-20 with 50/50 features: configurable decimals, permit, pausability,
///         **tax on transfers** via OZ v5 `_update` hook, plus whitelist/blacklist.
/// @dev Core logic resides in _update: check paused → check blacklist → evaluate tax-exempt paths → split the transfer into two legs for taxation.
///      - Tax is expressed in **basis points** (bps), where 1% = 100 bps.
///      - Rounding: fee = floor(amount * taxBps / 10_000); receiver gets remainder.
///      - `Ownable(initialOwner_)` sets deploy-time owner; `ERC20Permit(name_)` enables permit().
contract TaxedERC20 is ERC20, ERC20Permit, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ---------- Storage ----------

    /// @notice Custom decimals returned by {decimals()}.
    uint8 private _decimals_;

    /// @notice Transfer tax in basis points (1% = 100). Capped at 10% (1,000 bps).
    uint16 public taxBps;

    /// @notice Address that receives collected tax.
    address public taxCollector;

    /// @notice Addresses exempt from tax (either side whitelisted => no tax).
    mapping(address => bool) public whitelist;

    /// @notice Addresses blocked from sending/receiving while blacklisted.
    mapping(address => bool) public blacklist;

    // ---------- Events ----------

    /// @notice Emitted when tax rate or collector is updated.
    /// @param bps New tax in basis points.
    /// @param collector New tax collector address.
    event TaxUpdated(uint16 bps, address collector);

    /// @notice Emitted when an address is added/removed from whitelist.
    /// @param acct The account updated.
    /// @param allowed True to whitelist, false to remove.
    event WhitelistSet(address indexed acct, bool allowed);

    /// @notice Emitted when an address is added/removed from blacklist.
    /// @param acct The account updated.
    /// @param blocked True to blacklist, false to remove.
    event BlacklistSet(address indexed acct, bool blocked);

    // ---------- Constructor ----------

    /// @param name_           Token name.
    /// @param symbol_         Token symbol.
    /// @param decimals_       Token decimals (returned by {decimals()}).
    /// @param initialSupply_  Initial supply (already scaled by 10**decimals_).
    /// @param initialOwner_   Initial owner and recipient of the initial mint.
    /// @param taxBps_         Initial tax in bps (max 1,000 = 10%).
    /// @param taxCollector_   Tax collector (non-zero).
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialOwner_,
        uint16 taxBps_,
        address taxCollector_
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(initialOwner_) {
        require(taxBps_ <= 1000, "tax too high"); // 10% cap
        require(taxCollector_ != address(0), "collector zero");

        _decimals_ = decimals_;
        taxBps = taxBps_;
        taxCollector = taxCollector_;

        _mint(initialOwner_, initialSupply_);
    }

    // ---------- Admin (onlyOwner) ----------

    /// @notice Update both the tax rate and the collector in one call.
    /// @dev `newBps` must be ≤ 1,000 (10%). `newCollector` must be non-zero.
    /// @param newBps New tax in basis points.
    /// @param newCollector New tax collector address.
    function setTax(uint16 newBps, address newCollector) external onlyOwner {
        require(newBps <= 1000, "tax too high");
        require(newCollector != address(0), "collector zero");
        taxBps = newBps;
        taxCollector = newCollector;
        emit TaxUpdated(newBps, newCollector);
    }

    /// @notice Add or remove an address from the whitelist (tax-exempt).
    /// @param user Address to update.
    /// @param allowed True to whitelist, false to remove.
    function setWhitelist(address user, bool allowed) external onlyOwner {
        whitelist[user] = allowed;
        emit WhitelistSet(user, allowed);
    }

    /// @notice Add or remove an address from the blacklist (cannot send/receive).
    /// @param user Address to update.
    /// @param blocked True to blacklist, false to remove.
    function setBlacklist(address user, bool blocked) external onlyOwner {
        blacklist[user] = blocked;
        emit BlacklistSet(user, blocked);
    }

    /// @notice Pause all token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Recover unrelated ERC-20 tokens mistakenly sent to this contract.
    /// @dev Uses SafeERC20. Does not handle native ETH.
    /// @param token ERC-20 token to recover.
    /// @param amount Amount to transfer to the owner.
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ---------- Views ----------

    /// @notice Returns the custom decimals configured at deployment.
    function decimals() public view override returns (uint8) {
        return _decimals_;
    }

    // ---------- Core hook (OZ v5) ----------

    /// @dev Centralized transfer/mint/burn hook.
    ///      Flow:
    ///        (1) Check not paused.
    ///        (2) Block if either `from` or `to` is blacklisted.
    ///        (3) Tax-exempt if mint (`from==0`), burn (`to==0`), either side whitelisted, or `taxBps==0`.
    ///        (4) Otherwise charge `fee = floor(amount * taxBps / 10_000)` to `taxCollector`,
    ///            then transfer the remainder to `to`.
    ///      Rationale: using `_update` ensures consistent logic for transfer/mint/burn.
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // (1) Global pause
        _requireNotPaused();

        // (2) Blacklist checks (both directions)
        require(!blacklist[from] && !blacklist[to], "Blacklisted");

        // (3) Tax-exempt paths: mint / burn / either side whitelisted / zero tax
        if (
            from == address(0) || // mint
            to == address(0) || // burn
            whitelist[from] ||
            whitelist[to] ||
            taxBps == 0
        ) {
            super._update(from, to, amount);
            return;
        }

        // (4) Taxed transfer: split into (from → taxCollector, fee) + (from → to, net)
        uint256 fee = (amount * taxBps) / 10_000; // floor rounding
        if (fee > 0) {
            // taxCollector is guaranteed non-zero by constructor/setTax
            super._update(from, taxCollector, fee);
            amount -= fee;
        }

        super._update(from, to, amount);
    }
}
