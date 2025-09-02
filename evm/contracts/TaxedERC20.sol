// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TaxedERC20 (OZ v5-ready)
/// @notice 基于 _update 钩子的征税、黑白名单与可暂停逻辑；支持自定义 decimals 与 ERC20Permit
contract TaxedERC20 is ERC20, ERC20Permit, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ---------- Storage ----------
    uint8 private _decimals_; // 自定义小数位
    uint16 public taxBps; // 基点（1% = 100）
    address public taxCollector; // 收税地址
    mapping(address => bool) public whitelist; // 白名单：免税
    mapping(address => bool) public blacklist; // 黑名单：禁止转入/转出

    // ---------- Events ----------
    event TaxUpdated(uint16 bps, address collector);
    event WhitelistSet(address indexed acct, bool allowed);
    event BlacklistSet(address indexed acct, bool blocked);

    // ---------- Constructor ----------
    /// @param name_  代币名
    /// @param symbol_ 代币符号
    /// @param decimals_ 小数位
    /// @param initialSupply_ 初始铸造量（按 decimals_ 计）
    /// @param initialOwner_  初始 owner 及接收初始铸造
    /// @param taxBps_ 税率（基点，上限 1000 = 10%）
    /// @param taxCollector_ 收税地址（不可为 0）
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialOwner_,
        uint16 taxBps_,
        address taxCollector_
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(initialOwner_) {
        require(taxBps_ <= 1000, "tax too high"); // 10% 上限
        require(taxCollector_ != address(0), "collector zero");

        _decimals_ = decimals_;
        taxBps = taxBps_;
        taxCollector = taxCollector_;

        _mint(initialOwner_, initialSupply_);
    }

    // ---------- Admin (onlyOwner) ----------
    /// @notice 同时设置税率与收税地址（推荐接口）
    function setTax(uint16 newBps, address newCollector) external onlyOwner {
        require(newBps <= 1000, "tax too high");
        require(newCollector != address(0), "collector zero");
        taxBps = newBps;
        taxCollector = newCollector;
        emit TaxUpdated(newBps, newCollector);
    }

    function setWhitelist(address user, bool allowed) external onlyOwner {
        whitelist[user] = allowed;
        emit WhitelistSet(user, allowed);
    }

    function setBlacklist(address user, bool blocked) external onlyOwner {
        blacklist[user] = blocked;
        emit BlacklistSet(user, blocked);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice 误转回收（owner 取回本合约里“其他 ERC20”）
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ---------- Views ----------
    function decimals() public view override returns (uint8) {
        return _decimals_;
    }

    // ---------- Core hook (OZ v5) ----------
    /// @dev 统一处理转账/铸造/销毁；此处加入：暂停、黑名单与征税
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // 1) 全局暂停
        _requireNotPaused(); // OZ Pausable 内部函数

        // 2) 黑名单拦截（含转入与转出）
        require(!blacklist[from] && !blacklist[to], "Blacklisted");

        // 3) 免税场景：mint/burn/白名单任一方/税率为 0
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

        // 4) 征税：拆两笔 (from -> taxCollector, fee) 与 (from -> to, amount - fee)
        uint256 fee = (amount * taxBps) / 10_000;
        if (fee > 0) {
            // 收税：仅在收税地址非 zero（构造与 setTax 已校验）时执行
            super._update(from, taxCollector, fee);
            amount -= fee;
        }

        super._update(from, to, amount);
    }
}
