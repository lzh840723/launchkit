// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";
import {SimpleERC20} from "../contracts/tokens/SimpleERC20.sol";

/// @notice Custom errors mirrored from TokenFactory for selector-based revert checks.
error NameEmpty();
error SymbolEmpty();
error SymbolTooLong();
error DecimalsOutOfRange();
error SupplyZero();
error OwnerZero();

/// @title TokenFactoryTest
/// @notice Foundry tests for {TokenFactory}: success flow, event emission,
///         input validation reverts, and owner gating while the factory is closed.
contract TokenFactoryTest is Test {
    TokenFactory factory;

    /// @notice Acts as the factory owner/deployer in tests.
    address deployer = address(0xA11CE);
    /// @notice Non-owner used for negative permission tests.
    address alice = address(0xB0B);

    /// @notice Event mirrored for expectEmit() assertions.
    event TokenCreated(
        address indexed token,
        address indexed owner,
        string name,
        string symbol,
        uint8 decimals,
        uint256 initialSupply
    );

    /// @notice Deploy a fresh factory with `deployer` as owner.
    /// @dev Default state: closed (only owner can create).
    function setUp() public {
        vm.prank(deployer);
        factory = new TokenFactory(deployer); // constructor sets owner = msg.sender
    }

    /// @notice Creating a token succeeds and emits `TokenCreated` with expected fields.
    /// @dev Uses expectEmit with topic2 (owner) and data checks; token address (topic1) is unknown at compile time.
    function test_Create_Success_And_Event() public {
        vm.prank(deployer);

        // We don't know the token address in advance, so skip topic1; assert owner (topic2) + data.
        vm.expectEmit(false, true, false, true);
        emit TokenCreated(address(0), deployer, "MyToken", "MYT", 18, 1e18);

        address token = factory.createToken(
            "MyToken",
            "MYT",
            18,
            1e18,
            deployer
        );
        assertTrue(token != address(0));

        // Additional state assertions
        SimpleERC20 t = SimpleERC20(token);
        assertEq(t.name(), "MyToken");
        assertEq(t.symbol(), "MYT");
        assertEq(t.decimals(), 18);
        assertEq(t.balanceOf(deployer), 1e18);
    }

    /// @notice Reverts when name is empty.
    function test_Revert_NameEmpty() public {
        vm.prank(deployer);
        vm.expectRevert(NameEmpty.selector);
        factory.createToken("", "MYT", 18, 1e18, deployer);
    }

    /// @notice Reverts when symbol exceeds policy length.
    function test_Revert_SymbolTooLong() public {
        vm.prank(deployer);
        vm.expectRevert(SymbolTooLong.selector);
        factory.createToken("MyToken", "SUPERSUPERLONG", 18, 1e18, deployer);
    }

    /// @notice Reverts when initial supply is zero.
    function test_Revert_SupplyZero() public {
        vm.prank(deployer);
        vm.expectRevert(SupplyZero.selector);
        factory.createToken("MyToken", "MYT", 18, 0, deployer);
    }

    /// @notice Non-owner cannot create when the factory is closed (`isOpen == false`).
    /// @dev Checks OZ v5 `OwnableUnauthorizedAccount(address)` selector with the caller address encoded.
    function test_Revert_NonOwner_WhenClosed() public {
        vm.prank(alice);
        bytes4 sel = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(sel, alice));
        factory.createToken("MyToken", "MYT", 18, 1e18, alice);
    }
}
