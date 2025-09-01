// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";
import {SimpleERC20} from "../contracts/tokens/SimpleERC20.sol";

error NameEmpty();
error SymbolEmpty();
error SymbolTooLong();
error DecimalsOutOfRange();
error SupplyZero();
error OwnerZero();

contract TokenFactoryTest is Test {
    TokenFactory factory;
    address deployer = address(0xA11CE);
    address alice = address(0xB0B);

    event TokenCreated(
        address indexed token,
        address indexed owner,
        string name,
        string symbol,
        uint8 decimals,
        uint256 initialSupply
    );

    function setUp() public {
        vm.prank(deployer);
        factory = new TokenFactory(deployer); // 构造里 owner = msg.sender
        // 默认关闭：仅 owner 可创建
    }

    function test_Create_Success_And_Event() public {
        vm.prank(deployer);

        // 我们不知道 token 地址，故跳过 topic1 校验；校验 owner（topic2）+ data
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

        // 进一步状态断言
        SimpleERC20 t = SimpleERC20(token);
        assertEq(t.name(), "MyToken");
        assertEq(t.symbol(), "MYT");
        assertEq(t.decimals(), 18);
        assertEq(t.balanceOf(deployer), 1e18);
    }

    function test_Revert_NameEmpty() public {
        vm.prank(deployer);
        vm.expectRevert(NameEmpty.selector);
        factory.createToken("", "MYT", 18, 1e18, deployer);
    }

    function test_Revert_SymbolTooLong() public {
        vm.prank(deployer);
        vm.expectRevert(SymbolTooLong.selector);
        factory.createToken("MyToken", "SUPERSUPERLONG", 18, 1e18, deployer);
    }

    function test_Revert_SupplyZero() public {
        vm.prank(deployer);
        vm.expectRevert(SupplyZero.selector);
        factory.createToken("MyToken", "MYT", 18, 0, deployer);
    }

    function test_Revert_NonOwner_WhenClosed() public {
        vm.prank(alice);
        // OZ v5 OwnableUnauthorizedAccount(address) 选择器
        bytes4 sel = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(sel, alice));
        factory.createToken("MyToken", "MYT", 18, 1e18, alice);
    }
}
