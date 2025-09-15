// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable}   from "@openzeppelin/contracts/access/Ownable.sol";
import {TaxedERC20} from "./TaxedERC20.sol"; // 导入 TaxedERC20

error NameEmpty();
error SymbolEmpty();
error SymbolTooLong();
error DecimalsOutOfRange();
error SupplyZero();
error OwnerZero();

/// @notice Emitted after a successful token deployment.
/// @param token Newly created token address.
/// @param owner Initial owner / initial mint recipient of the token.
/// @param name Token name.
/// @param symbol Token symbol (≤ 11 chars).
/// @param decimals Token decimals.
/// @param initialSupply Initial supply in base units (scaled by 10**decimals).
event TokenCreated(
    address indexed token,
    address indexed owner,
    string  name,
    string  symbol,
    uint8   decimals,
    uint256 initialSupply
);


/// @title TokenFactory
/// @notice Minimal factory that deploys {TaxedERC20} tokens with basic policy checks.
/// @dev
/// - Gating: when {isOpen} is false, only the factory owner can create; when true, anyone can.
/// - New tokens are initialized with: taxBps = 200 (2%), taxCollector = factory owner().
/// - `initialSupply_` must already be scaled by 10**decimals_.
contract TokenFactory is Ownable {
    /// @notice Public switch: if true, anyone may call {createToken}; if false, only owner.
    bool public isOpen;

    /// @param initialOwner The factory owner (also used as taxCollector for created tokens).
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Toggle public creation capability.
    /// @param open True to allow anyone to create; false to restrict to owner only.
    function setOpen(bool open) external onlyOwner { isOpen = open; }

    /// @notice Allows calls from the owner, or from anyone when {isOpen} is true.
    /// @dev Reverts with OZ v5 namespaced error when unauthorized.
    modifier onlyOwnerOrOpen() {
        if (!isOpen && msg.sender != owner()) {
            revert Ownable.OwnableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /// @notice Deploy a new {TaxedERC20} with the provided metadata and initial mint.
    /// @dev
    /// - Validation: name/symbol non-empty; symbol length ≤ 11; decimals in [6,18];
    ///   initialSupply_ > 0; tokenOwner_ non-zero.
    /// - Initialization: taxBps = 200 (2%), taxCollector = factory owner().
    /// - `initialSupply_` must already include decimals scaling (base units).
    /// @param name_          Token name (non-empty).
    /// @param symbol_        Token symbol (non-empty, ≤ 11 chars).
    /// @param decimals_      Token decimals in [6, 18].
    /// @param initialSupply_ Initial supply (base units, > 0).
    /// @param tokenOwner_    Initial owner and mint recipient (non-zero).
    /// @return token Address of the newly created token.
    function createToken(
        string memory name_,
        string memory symbol_,
        uint8   decimals_,
        uint256 initialSupply_,
        address tokenOwner_
    ) external onlyOwnerOrOpen returns (address token) {
        if (bytes(name_).length == 0) revert NameEmpty();
        if (bytes(symbol_).length == 0) revert SymbolEmpty();
        if (bytes(symbol_).length > 11) revert SymbolTooLong();
        if (decimals_ < 6 || decimals_ > 18) revert DecimalsOutOfRange();
        if (initialSupply_ == 0) revert SupplyZero();
        if (tokenOwner_ == address(0)) revert OwnerZero();

        token = address(
            new TaxedERC20(
                name_,
                symbol_,
                decimals_,
                initialSupply_,
                tokenOwner_,
                200,          // taxBps = 2%
                owner()       // taxCollector = 工厂 owner
            )
        );

        emit TokenCreated(token, tokenOwner_, name_, symbol_, decimals_, initialSupply_);
    }
}
