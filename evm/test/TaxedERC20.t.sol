// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

contract TaxedERC20Test is Test {
    TaxedERC20 t;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address fee = address(0xFEE);

    function setUp() public {
        // 初始代币直接发给 alice，避免 setUp 阶段产生税
        t = new TaxedERC20("Tax", "TAX", 1_000 ether, alice, 300, fee); // 3% = 300 bps
    }

    function test_taxedTransfer() public {
        vm.prank(alice);
        assertTrue(t.transfer(bob, 10 ether)); // 3% 税
        assertEq(t.balanceOf(bob), 9.7 ether);
        assertEq(t.balanceOf(fee), 0.3 ether);
    }

    function test_whitelistNoTax() public {
        // onlyOwner：用合约 owner 身份设置白名单
        vm.prank(t.owner());
        t.setWhitelist(alice, true);

        vm.prank(alice);
        assertTrue(t.transfer(bob, 10 ether));
        assertEq(t.balanceOf(bob), 10 ether);
        assertEq(t.balanceOf(fee), 0);
    }

    function test_pause() public {
        vm.prank(t.owner());
        t.pause();

        vm.prank(alice);
        bool reverted;
        try t.transfer(bob, 1 ether) returns (bool) {
            // 注意：没有命名返回值
            reverted = false; // 不应到这
            fail(); // forge-std 的 fail()，到这说明没 revert
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "transfer should revert when paused");
    }

    function test_TaxDistribution() public {
        address collector = address(0xC0FFEE);
        TaxedERC20 token2 = new TaxedERC20(
            "T",
            "T",
            1000 ether,
            address(this),
            200,
            collector
        ); // 2%

        // 让第一笔 owner -> alice 免税
        vm.prank(token2.owner());
        token2.setWhitelist(token2.owner(), true);

        // 现在 alice 可拿到完整的 100
        assertTrue(token2.transfer(alice, 100 ether));

        // 第二笔 alice -> bob 按 2% 扣税：bob 98，collector +2
        vm.prank(alice);
        assertTrue(token2.transfer(bob, 100 ether));

        assertEq(token2.balanceOf(bob), 98 ether);
        assertEq(token2.balanceOf(collector), 2 ether);
    }

    function test_taxedTransferFrom() public {
        // alice -> bob 10 ether，通过 transferFrom
        vm.prank(alice);
        t.approve(address(this), 10 ether);

        assertTrue(t.transferFrom(alice, bob, 10 ether));
        assertEq(t.balanceOf(bob), 9.7 ether);
        assertEq(t.balanceOf(fee), 0.3 ether);
    }

    event TaxBpsUpdated(uint16 oldBps, uint16 newBps);
    event TaxCollectorUpdated(
        address indexed oldCollector,
        address indexed newCollector
    );

    function test_SetTaxBps_RevertOverCap() public {
        vm.prank(t.owner());
        vm.expectRevert(bytes("tax too high"));
        t.setTaxBps(1001);
    }

    function test_SetTaxBps_And_Event() public {
        vm.prank(t.owner());
        vm.expectEmit(true, true, true, true);
        emit TaxBpsUpdated(300, 500);
        t.setTaxBps(500);
        assertEq(t.taxBps(), 500);
    }

    function test_SetTaxCollector_And_Event() public {
        address newCollector = address(0xABCD);
        vm.prank(t.owner());
        vm.expectEmit(true, true, true, true);
        emit TaxCollectorUpdated(address(0xFEE), newCollector);
        t.setTaxCollector(newCollector);
        assertEq(t.taxCollector(), newCollector);
    }
}
