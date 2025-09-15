// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

/// @title MockERC20
/// @notice Minimal mintable ERC-20 used for FeeRouter tests.
contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MOCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

/// @title FeeRouterTest
/// @notice Foundry tests for FeeRouter:
///         - Owner can update beneficiaries
///         - withdraw() splits contract balance 50/50 to platform & creator
contract FeeRouterTest is Test {
    FeeRouter internal router;
    MockERC20 internal token;
    address internal owner;
    address internal platform;
    address internal creator;
    address internal user;

    /// @notice Set up roles, deploy router (with platform/creator), and mint test funds to `user`.
    function setUp() public {
        owner    = makeAddr("OWNER");
        platform = makeAddr("PLATFORM");
        creator  = makeAddr("CREATOR");
        user     = makeAddr("USER");

        // Deploy router as `owner`
        vm.startPrank(owner);
        router = new FeeRouter(platform, creator);
        vm.stopPrank();

        // Create mock token and fund `user`
        token = new MockERC20();
        token.mint(user, 1_000 ether);
    }

    /// @notice Owner can update platform/creator via setBeneficiaries.
    function test_setBeneficiaries_onlyOwner() public {
        address p2 = makeAddr("P2");
        address c2 = makeAddr("C2");
        vm.prank(owner);
        router.setBeneficiaries(p2, c2);
        assertEq(router.platform(), p2);
        assertEq(router.creator(),  c2);
    }

    /// @notice withdraw() transfers entire token balance from router,
    ///         splitting it 50/50 between platform and creator.
    function test_withdraw_split50_50() public {
        // user sends 100 tokens to the router
        vm.startPrank(user);
        require(token.transfer(address(router), 100 ether), "ERC20 transfer failed");
        vm.stopPrank();

        uint256 pBefore = token.balanceOf(platform);
        uint256 cBefore = token.balanceOf(creator);

        // anyone can trigger withdraw()
        router.withdraw(address(token));

        assertEq(token.balanceOf(platform) - pBefore, 50 ether);
        assertEq(token.balanceOf(creator)  - cBefore, 50 ether);
        assertEq(token.balanceOf(address(router)), 0);
    }
}
