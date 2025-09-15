// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

/// @title Deploy (Foundry Script)
/// @notice Deploys a TokenFactory and logs its address.
/// @dev Environment (.env) variables:
/// - PRIVATE_KEY : broadcaster's private key (funded)
/// - OWNER       : target owner (also passed to TokenFactory constructor)
contract Deploy is Script {
    /// @notice Deploy the factory using the provided PRIVATE_KEY.
    /// @dev Flow: load env → startBroadcast → new TokenFactory(owner) → log → stopBroadcast.
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY"); // read private key from .env
        address owner = vm.envAddress("OWNER"); // target owner (already in your .env)

        vm.startBroadcast(pk); // ✅ broadcast with the private key
        TokenFactory f = new TokenFactory(owner); // If constructor doesn't take owner, use: new TokenFactory();
        // If the constructor doesn't take owner, then add next line: f.transferOwnership(owner);

        console2.log("TokenFactory re-deployed at:", address(f));
        vm.stopBroadcast();
    }
}
