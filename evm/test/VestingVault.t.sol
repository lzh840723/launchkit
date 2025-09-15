// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {VestingVault} from "../contracts/VestingVault.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

/**
 * @title VestingVaultTest
 * @notice Business-oriented tests to verify a linear vesting vault with a cliff behaves as expected
 *         at key timestamps and with correct role permissions.
 *
 * Covered scenarios:
 * 1) No releaseable tokens before the cliff (vested = 0);
 * 2) Linear vesting after the cliff: partial release mid-way; at the end all tokens are vested and can be fully released;
 * 3) Only the owner can fund the vault (must `approve` first, then `fund`);
 * 4) Both the beneficiary and the owner can call `release` (`amount = 0` means release all currently releasable tokens).
 */
contract VestingVaultTest is Test {
    // Use the project's TaxedERC20 as the token under test (set tax to 0 to avoid interference).
    TaxedERC20 token;

    // The vesting vault under test.
    VestingVault vault;

    // Key roles.
    address owner = address(0xA11CE); // Operator of the contract/vault (e.g., multisig/project)
    address bene  = address(0xB0B);   // Beneficiary (recipient)

    // Token specs.
    uint8   decs   = 18;
    uint256 supply = 1_000_000 * 1e18;

    function setUp() public {
        /**
         * Deploy a simple ERC-20 as the vested token:
         * name="T", symbol="T", decimals=18, supply minted to `owner`, tax=0, collector=owner.
         * Note: We reuse the project's TaxedERC20 for integration convenience; a plain ERC20
         *       could be used in production as well.
         */
        token = new TaxedERC20("T", "T", decs, supply, owner, 0, owner);

        // Timing: start in 100 seconds; total duration 30 days; cliff of 7 days.
        uint64 start    = uint64(block.timestamp) + 100;
        uint64 duration = 30 days;
        uint64 cliff    = 7 days;

        // Deploy the vault; initial owner = `owner`, beneficiary = `bene`.
        vault = new VestingVault(
            token,
            bene,
            start,
            duration,
            cliff,
            owner
        );

        // Whitelist `owner` to avoid any TaxedERC20 tax/risk controls affecting these tests.
        vm.prank(owner);
        token.setWhitelist(owner, true);
    }

    /**
     * @dev Helper: simulate the standard owner funding flow: approve + fund.
     */
    function _fund(uint256 amt) internal {
        vm.startPrank(owner);
        token.approve(address(vault), amt); // approve the vault first
        vault.fund(amt);                    // then fund from the owner
        vm.stopPrank();
    }

    /**
     * @notice Main flow: zero before cliff; linear after cliff; partial mid-way; fully vested at the end.
     */
    function test_flow_linear_with_cliff() public {
        uint256 amt = 100_000 * 1e18;
        _fund(amt); // total funded: 100,000 tokens

        // 1) Before the cliff: nothing releasable.
        vm.warp(vault.start() + vault.cliff() - 1);
        assertEq(vault.releasable(), 0, "should be 0 before cliff");

        // 2) After the cliff + 1 day: there should be some vested amount.
        vm.warp(vault.start() + vault.cliff() + 1 days);
        uint256 midAvail = vault.releasable();
        assertGt(midAvail, 0, "should be >0 after cliff");

        // 3) Beneficiary releases "half" of the current releasable amount.
        vm.prank(bene);
        vault.release(midAvail / 2);
        assertEq(token.balanceOf(bene), midAvail / 2, "beneficiary should receive half");

        // 4) Move to the end: there should be remaining releasable (total vested - already released).
        vm.warp(vault.start() + vault.duration());
        uint256 tail = vault.releasable();
        assertGt(tail, 0, "should be >0 at end");

        // 5) Owner can also trigger release; amount=0 means "release all currently available".
        vm.prank(owner);
        vault.release(0);

        // 6) After the final release: releasable should be 0; beneficiary balance = half(mid) + tail.
        assertEq(vault.releasable(), 0, "should be 0 after final release");
        assertEq(token.balanceOf(bene), (midAvail / 2) + tail, "beneficiary should receive all vested tokens");
    }

    /**
     * @notice Only the owner can fund; the owner must `approve` first, then `fund`.
     */
    function test_onlyOwner_can_fund() public {
        // Non-owner call should revert.
        vm.expectRevert();
        vault.fund(1e18);

        // Owner follows the standard flow: approve + fund.
        _fund(1e18);
        assertEq(vault.totalReceived(), 1e18, "totalReceived should match funded amount");
    }
}
