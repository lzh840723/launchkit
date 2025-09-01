// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable}   from "@openzeppelin/contracts/access/Ownable.sol";
import {SimpleERC20} from "./tokens/SimpleERC20.sol";

// ---- Day5: custom errors（省 gas） ----
error NameEmpty();
error SymbolEmpty();
error SymbolTooLong();
error DecimalsOutOfRange();
error SupplyZero();
error OwnerZero();

// ---- Day5: 事件字段补齐（证据友好） ----
event TokenCreated(
    address indexed token,
    address indexed owner,
    string  name,
    string  symbol,
    uint8   decimals,
    uint256 initialSupply
);

contract TokenFactory is Ownable {
    // 开关：false=仅 owner 可创建；true=对外开放（便于写失败用例）
    bool public isOpen;

    // OZ v5 需要在构造里传入初始 owner
    constructor(address initialOwner) Ownable(initialOwner) {}

    function setOpen(bool open) external onlyOwner { isOpen = open; }

    modifier onlyOwnerOrOpen() {
        if (!isOpen && msg.sender != owner()) {
            // OZ v5 的 revert：OwnableUnauthorizedAccount(address)
            revert Ownable.OwnableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /// @notice 最小可用创建：Day6 可替换为 TaxedERC20
    function createToken(
        string memory name_,
        string memory symbol_,
        uint8   decimals_,
        uint256 initialSupply_,
        address tokenOwner_
    ) external onlyOwnerOrOpen returns (address token) {
        // ---- Day5: 输入边界 ----
        if (bytes(name_).length == 0) revert NameEmpty();
        if (bytes(symbol_).length == 0) revert SymbolEmpty();
        if (bytes(symbol_).length > 11) revert SymbolTooLong();          // 11～12 皆可
        if (decimals_ < 6 || decimals_ > 18) revert DecimalsOutOfRange();
        if (initialSupply_ == 0) revert SupplyZero();
        if (tokenOwner_ == address(0)) revert OwnerZero();

        // ---- 最小实现（Day6 可替换为你的 TaxedERC20）----
        token = address(new SimpleERC20(name_, symbol_, decimals_, initialSupply_, tokenOwner_));

        emit TokenCreated(token, tokenOwner_, name_, symbol_, decimals_, initialSupply_);
    }
}
