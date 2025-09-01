// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/TokenFactory.sol";
import "../contracts/TaxedERC20.sol";

contract FactoryTest is Test {
    TokenFactory factory;
    address admin = address(this);
    address collector = address(0xC0FFEE);

    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 1_000 ether;

    function setUp() public {
        factory = new TokenFactory(admin); // onlyOwner = admin
    }

    function test_CreateToken_MintsToOwner() public {
        vm.prank(admin);
        address tokenAddr = factory.createToken(
            "Test",
            "T",
            DECIMALS,
            TOTAL_SUPPLY,
            admin 
        );
        TaxedERC20 t = TaxedERC20(tokenAddr);

        // 初始供应发给 owner（构造参数里传的 owner()）
        assertEq(t.totalSupply(), 1_000 ether);
        assertEq(t.balanceOf(admin), 1_000 ether);
    }

    function test_OnlyOwnerCanCreate() public {
        address stranger = address(0x4444);
        vm.expectRevert(); // Ownable: caller is not the owner
        vm.prank(stranger);
        factory.createToken("Fail", "F", DECIMALS, 1 ether, collector);
    }
}
