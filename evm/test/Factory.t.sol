// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/TokenFactory.sol";
import "../contracts/TaxedERC20.sol";

contract FactoryTest is Test {
    TokenFactory factory;
    address admin     = address(this);
    address collector = address(0xC0FFEE);

    function setUp() public {
        factory = new TokenFactory(admin); // onlyOwner = admin
    }

    function test_CreateToken_MintsToOwner() public {
        vm.prank(admin);
        address tokenAddr = factory.createToken(
            "Test", "T",
            1_000 ether,
            200,            // 2% (bps)
            collector
        );
        TaxedERC20 t = TaxedERC20(tokenAddr);

        // 初始供应发给 owner（构造参数里传的 owner()）
        assertEq(t.totalSupply(), 1_000 ether);
        assertEq(t.balanceOf(admin), 1_000 ether);
    }

    function test_OnlyOwnerCanCreate() public {
        address stranger = address(0x4444);
        vm.expectRevert();                 // Ownable: caller is not the owner
        vm.prank(stranger);
        factory.createToken("Fail", "F", 1 ether, 200, collector);
    }
}
