// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

contract TaxedERC20Test is Test {
    TaxedERC20 t;
    address fee = address(0xFEE);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        t = new TaxedERC20("Tax", "TAX", 1_000 ether, address(this), 300, fee); // 3%
        t.transfer(alice, 100 ether);
    }

    function test_taxedTransfer() public {
        vm.prank(alice);
        t.transfer(bob, 10 ether); // 3% 税
        assertEq(t.balanceOf(bob), 9.7 ether);
        assertEq(t.balanceOf(fee), 0.3 ether);
    }

    function test_whitelistNoTax() public {
        t.setWhitelist(alice, true);
        vm.prank(alice);
        t.transfer(bob, 10 ether);
        assertEq(t.balanceOf(bob), 10 ether);
        assertEq(t.balanceOf(fee), 0);
    }

    function test_pause() public {
        t.pause();
        vm.expectRevert();
        t.transfer(bob, 1 ether);
    }
}
