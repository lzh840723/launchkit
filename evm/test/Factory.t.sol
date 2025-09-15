// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/TokenFactory.sol";
import "../contracts/TaxedERC20.sol";

/// @title FactoryTest
/// @notice Foundry tests for {TokenFactory} basic behaviors:
///         (1) creating a token mints the initial supply to the specified owner;
///         (2) only the factory owner can create tokens when `isOpen == false`.
contract FactoryTest is Test {
    TokenFactory factory;

    /// @notice Acts as the factory owner in these tests.
    address admin = address(this);

    /// @notice Unrelated address used in negative/permission tests.
    address collector = address(0xC0FFEE);

    /// @dev Chosen for readability; `1_000 ether` equals 1,000 * 10^18 base units.
    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1_000 ether;

    /// @notice Deploy a fresh factory before each test; `admin` is the owner.
    function setUp() public {
        factory = new TokenFactory(admin); // onlyOwner = admin
    }

    /// @notice Creating a token should mint the full initial supply to the provided owner.
    function test_CreateToken_MintsToOwner() public {
        // Impersonate `admin` (factory owner) for the next call.
        vm.prank(admin);
        address tokenAddr = factory.createToken(
            "Test",
            "T",
            DECIMALS,
            TOTAL_SUPPLY,
            admin 
        );

        TaxedERC20 t = TaxedERC20(tokenAddr);

        // Initial supply is minted to `admin` (the `tokenOwner_` passed to the factory).
        assertEq(t.totalSupply(), 1_000 ether);
        assertEq(t.balanceOf(admin), 1_000 ether);
    }

    /// @notice When `isOpen` is false (default), non-owners must not be able to create tokens.
    function test_OnlyOwnerCanCreate() public {
        address stranger = address(0x4444);

        // Expect the next call to revert due to Ownable restriction.
        vm.expectRevert(); // Ownable: caller is not the owner
        vm.prank(stranger);
        factory.createToken("Fail", "F", DECIMALS, 1 ether, collector);
    }
}
