// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error EnforcedPause();

contract TaxedERC20Test is Test {
    TaxedERC20 internal token;

    address internal alice; // 初始 owner & 初始持币者（from）
    address internal bob; // 收币者（to）
    address internal collector; // 收税地址

    uint8 internal decs;
    uint256 internal initialSupply; // 以 decs 为单位

    function setUp() public {
        // 命名地址（forge-std 提供）
        alice = makeAddr("ALICE");
        bob = makeAddr("BOB");
        collector = makeAddr("COLLECTOR");

        vm.label(alice, "ALICE");
        vm.label(bob, "BOB");
        vm.label(collector, "COLLECTOR");

        decs = 18;
        initialSupply = 1_000_000 * (10 ** uint256(decs)); // 100 万枚

        // taxBps = 200 （2%），初始 owner = alice，收税地址 = collector
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

    // ============ ① 征税路径：A→B 收税到 taxCollector ============
    function test_Tax_Transfer_Sends_Fee_To_Collector() public {
        uint256 amt = 1_000 * (10 ** uint256(decs)); // 转 1000
        uint256 fee = (amt * 200) / 10_000; // 2%
        uint256 net = amt - fee;

        // alice 发起转账
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

    // ============ ② 白名单免税 ============
    function test_Whitelist_Exempts_From_Tax() public {
        // owner = alice；由 owner 设置白名单
        vm.prank(alice);
        token.setWhitelist(alice, true);

        uint256 amt = 2_000 * (10 ** uint256(decs));

        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");

        assertEq(token.balanceOf(bob), amt, "full amount to bob");
        assertEq(token.balanceOf(collector), 0, "no tax collected");
    }

    // ============ ③ 黑名单阻断 ============
    function test_Blacklist_Blocks_Transfer() public {
        vm.prank(alice);
        token.setBlacklist(alice, true); // 自己拉黑自己

        uint256 amt = 100 * (10 ** uint256(decs));

        vm.expectRevert(bytes("Blacklisted"));
        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");
    }

    // ============ ④ 暂停阻断 ============
    function test_Pause_Blocks_Transfer() public {
        vm.prank(alice);
        token.pause();

        uint256 amt = 100 * (10 ** uint256(decs));

        vm.expectRevert(EnforcedPause.selector);
        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");
    }

    // ======== 可选 ⑤：onlyOwner 限制（举两个接口） ========
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

    // ======== ⑥：decimals 生效 & 初始铸造一致 ========
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
