// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MOCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract FeeRouterTest is Test {
    FeeRouter internal router;
    MockERC20 internal token;
    address internal owner;
    address internal platform;
    address internal creator;
    address internal user;

    function setUp() public {
        owner    = makeAddr("OWNER");
        platform = makeAddr("PLATFORM");
        creator  = makeAddr("CREATOR");
        user     = makeAddr("USER");

        vm.startPrank(owner);
        router = new FeeRouter(platform, creator);
        vm.stopPrank();

        token = new MockERC20();
        token.mint(user, 1_000 ether);
    }

    function test_setBeneficiaries_onlyOwner() public {
        address p2 = makeAddr("P2");
        address c2 = makeAddr("C2");
        vm.prank(owner);
        router.setBeneficiaries(p2, c2);
        assertEq(router.platform(), p2);
        assertEq(router.creator(),  c2);
    }

    function test_withdraw_split50_50() public {
        vm.startPrank(user);
        require(token.transfer(address(router), 100 ether), "ERC20 transfer failed");
        vm.stopPrank();

        uint256 pBefore = token.balanceOf(platform);
        uint256 cBefore = token.balanceOf(creator);

        router.withdraw(address(token));

        assertEq(token.balanceOf(platform) - pBefore, 50 ether);
        assertEq(token.balanceOf(creator)  - cBefore, 50 ether);
        assertEq(token.balanceOf(address(router)), 0);
    }
}
