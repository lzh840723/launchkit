// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

/// @title Integration_Router_TaxedERC20 (Foundry Test)
/// @notice Integration test covering the end-to-end fee flow:
///         1) TaxedERC20 charges a 2% transfer tax to the configured collector;
///         2) The collector is set to a FeeRouter;
///         3) FeeRouter.withdraw() splits the collected tokens 50/50 to platform & creator;
///         4) Router is whitelisted before withdrawing so the withdraw transfer is tax-exempt.
contract Integration_Router_TaxedERC20 is Test {
    FeeRouter internal router;
    TaxedERC20 internal token;

    address internal alice; // token owner & initial holder
    address internal bob;   // receiver
    address internal platform;
    address internal creator;

    uint8 internal decs;
    uint256 internal initialSupply;

    /// @notice Deploy router and token, then set the token’s tax collector to the router.
    function setUp() public {
        alice    = makeAddr("ALICE");
        bob      = makeAddr("BOB");
        platform = makeAddr("PLATFORM");
        creator  = makeAddr("CREATOR");

        decs = 18;
        initialSupply = 1_000_000 * (10 ** uint256(decs));

        router = new FeeRouter(platform, creator);

        // Start with any collector (here: platform); we’ll switch to router via setTax().
        token = new TaxedERC20(
            "Taxed",
            "TT",
            decs,
            initialSupply,
            alice,
            200,        // 2% = 200 bps
            platform
        );

        // As owner (alice), update tax collector to the router (still 2%).
        vm.prank(alice);
        token.setTax(200, address(router));
    }

    /// @notice Verify: transfer collects fee to router; router.withdraw() splits 50/50.
    function test_tax_flow_and_router_withdraw() public {
        uint256 amt = 1_000 * (10 ** uint256(decs));     // transfer amount (1000 tokens)
        uint256 fee = (amt * 200) / 10_000;              // 2% fee (floor)

        // Transfer from alice to bob ⇒ fee should be sent to router by TaxedERC20.
        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");

        // Router should have accumulated the fee.
        assertEq(token.balanceOf(address(router)), fee);

        uint256 pBefore = token.balanceOf(platform);
        uint256 cBefore = token.balanceOf(creator);

        // Make router tax-exempt so that withdrawing does not incur another tax.
        vm.prank(alice);
        token.setWhitelist(address(router), true);

        // Anyone can trigger withdraw; splits fee 50/50 (odd handled by remainder).
        router.withdraw(address(token));

        assertEq(
            token.balanceOf(address(router)),
            0,
            "router should be emptied after withdraw when router is tax-exempt"
        );
        assertEq(token.balanceOf(platform), pBefore + fee / 2);
        assertEq(token.balanceOf(creator),  cBefore + (fee - fee / 2));
    }
}
