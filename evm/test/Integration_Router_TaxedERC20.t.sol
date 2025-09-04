// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

contract Integration_Router_TaxedERC20 is Test {
    FeeRouter internal router;
    TaxedERC20 internal token;

    address internal alice; // token owner & 初始持币者
    address internal bob; // 收币者
    address internal platform;
    address internal creator;

    uint8 internal decs;
    uint256 internal initialSupply;

    function setUp() public {
        alice = makeAddr("ALICE");
        bob = makeAddr("BOB");
        platform = makeAddr("PLATFORM");
        creator = makeAddr("CREATOR");

        decs = 18;
        initialSupply = 1_000_000 * (10 ** uint256(decs));

        router = new FeeRouter(platform, creator);

        // 初始收税地址随便给个占位，随后用 setTax 改为 router
        token = new TaxedERC20(
            "Taxed",
            "TT",
            decs,
            initialSupply,
            alice,
            200,
            platform
        );

        // 作为 owner(alice) 修改到 router
        vm.prank(alice);
        token.setTax(200, address(router));
    }

    function test_tax_flow_and_router_withdraw() public {
        uint256 amt = 1_000 * (10 ** uint256(decs)); // 转1000
        uint256 fee = (amt * 200) / 10_000; // 2%

        vm.prank(alice);
        require(token.transfer(bob, amt), "ERC20 transfer failed");

        // Router 应累计到 fee
        assertEq(token.balanceOf(address(router)), fee);

        uint256 pBefore = token.balanceOf(platform);
        uint256 cBefore = token.balanceOf(creator);

        router.withdraw(address(token));

        assertEq(token.balanceOf(address(router)), 0);
        assertEq(token.balanceOf(platform), pBefore + fee / 2);
        assertEq(token.balanceOf(creator), cBefore + (fee - fee / 2));
    }
}
