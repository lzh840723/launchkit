// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error EnforcedPause();
error Blacklisted();

/// @title TaxedERC20Test
/// @notice Foundry tests for core behaviors of {TaxedERC20}:
///         ① transfer tax collection ② whitelist tax-exemption
///         ③ blacklist blocking ④ pause blocking ⑤ onlyOwner guards
///         ⑥ decimals & initial mint sanity checks
contract TaxedERC20Test is Test {
    TaxedERC20 internal token;

    address internal alice;      // initial owner & initial holder (from)
    address internal bob;        // receiver (to)
    address internal collector;  // tax collector

    uint8 internal decs;
    uint256 internal initialSupply; // already scaled by `decs`

    function setUp() public {
        // Named addresses (via forge-std)
        alice     = makeAddr("ALICE");
        bob       = makeAddr("BOB");
        collector = makeAddr("COLLECTOR");

        vm.label(alice, "ALICE");
        vm.label(bob, "BOB");
        vm.label(collector, "COLLECTOR");

        decs = 18;
        initialSupply = 1_000_000 * (10 ** uint256(decs)); // 1,000,000 tokens

        // taxBps = 200 (2%), initial owner = alice, tax collector = collector
        token = new TaxedERC20(
            "Taxed Token",
            "TT",
            decs,
            initialSupply,
            alice,
            200,
            collector
        );
    }

    // ============ ① Tax path: A → B, fee goes to taxCollector ============
    function test_Tax_Transfer_Sends_Fee_To_Collector() public {
        uint256 amt = 1_000 * (10 ** uint256(decs)); // transfer 1000
        uint256 fee = (amt * 200) / 10_000;          // 2%
        uint256 net = amt - fee;

        // alice initiates the transfer
        vm.prank(alice);
        bool ok = token.transfer(bob, amt);
        assertTrue(ok);

        assertEq(token.balanceOf(bob), net, "bob should get net");
        assertEq(token.balanceOf(collector), fee, "collector should get fee");
        assertEq(
            token.balanceOf(alice),
            initialSupply - amt,
            "alice debited full amt"
        );
    }

    // ============ ② Whitelist exempts from tax ============
    function test_Whitelist_Exempts_From_Tax() public {
        // owner = alice; whitelist set by owner
        vm.prank(alice);
        token.setWhitelist(alice, true);

        uint256 amt = 2_000 * (10 ** uint256(decs));

        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");

        assertEq(token.balanceOf(bob), amt, "full amount to bob");
        assertEq(token.balanceOf(collector), 0, "no tax collected");
    }

    // ============ ③ Blacklist blocks transfer ============
    function test_Blacklist_Blocks_Transfer() public {
        vm.prank(alice);
        token.setBlacklist(alice, true);

        uint256 amt = 100 * (10 ** uint256(decs));

        vm.prank(alice);
        vm.expectRevert(); // blacklisted sender or receiver should revert
        token.transfer(bob, amt);
    }

    // ============ ④ Pause blocks transfer ============
    function test_Pause_Blocks_Transfer() public {
        vm.prank(alice);
        token.pause();

        uint256 amt = 100 * (10 ** uint256(decs));

        // OZ Pausable v5 reverts with custom error EnforcedPause()
        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        vm.prank(alice);
        token.transfer(bob, amt);
    }

    // ======== ⑤ onlyOwner guards (two example endpoints) ========
    function test_OwnerOnly_Functions_Revert_For_NonOwner() public {
        address stranger = makeAddr("STRANGER");

        // setTax
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                stranger
            )
        );
        vm.prank(stranger);
        token.setTax(100, collector);

        // setWhitelist
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                stranger
            )
        );
        vm.prank(stranger);
        token.setWhitelist(stranger, true);
    }

    // ======== ⑥ decimals applied & initial mint matches ========
    function test_Decimals_And_Initial_Mint() public view {
        assertEq(token.decimals(), decs, "decimals should match constructor");
        assertEq(
            token.totalSupply(),
            initialSupply,
            "totalSupply should equal initial mint"
        );
        assertEq(
            token.balanceOf(alice),
            initialSupply,
            "alice got full initial mint"
        );
    }
}
