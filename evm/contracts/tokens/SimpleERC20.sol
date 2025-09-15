// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SimpleERC20
/// @notice Minimal ERC-20 token with configurable decimals and a one-time initial mint to a specified owner.
/// @dev Built on OpenZeppelin {ERC20}. The decimals are set once in the constructor and returned by overriding
///      {decimals()}. `initialSupply_` should be provided in base units (already scaled by 10**decimals_).
contract SimpleERC20 is ERC20 {
    /// @notice Token decimals returned by {decimals()}.
    /// @dev Stored as an immutable to save gas after deployment.
    uint8 private immutable _decimals;

    /// @notice Deploy the token and mint the initial supply to `initialOwner_`.
    /// @param name_          Token name.
    /// @param symbol_        Token symbol.
    /// @param decimals_      Number of decimals the token uses.
    /// @param initialSupply_ Initial supply in base units (scaled by 10**decimals_).
    /// @param initialOwner_  Recipient of the initial supply.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address initialOwner_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _mint(initialOwner_, initialSupply_);
    }

    /// @notice Returns the number of decimals used to get the user representation.
    /// @dev Overrides OpenZeppelin's default of 18.
    /// @return The decimals configured at construction time.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
