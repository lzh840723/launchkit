// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

/// @title RouterWithdraw (Foundry Script)
/// @notice Triggers {FeeRouter.withdraw} for a given ERC20 token.
/// @dev Environment (.env):
/// - PRIVATE_KEY : broadcaster’s private key (funded for gas)
/// - ROUTER      : deployed FeeRouter address
/// - TOKEN       : ERC20 token address to withdraw/split
/// Flow: load env → startBroadcast → FeeRouter(r).withdraw(token) → stopBroadcast.
/// Note: {FeeRouter.withdraw} is permissionless in your implementation; caller only pays gas.
contract RouterWithdraw is Script {
    /// @notice Execute a single withdraw call on the target router.
    function run() external {
        uint256 pk   = vm.envUint("PRIVATE_KEY");
        address r    = vm.envAddress("ROUTER");
        address token= vm.envAddress("TOKEN");

        vm.startBroadcast(pk);
        FeeRouter(r).withdraw(token);
        vm.stopBroadcast();
    }
}
