// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

/// @title DeployFeeRouter (Foundry Script)
/// @notice Deploys a {FeeRouter} using values from environment variables.
/// @dev
/// Env (.env) variables expected:
/// - PRIVATE_KEY : broadcaster's private key (must be funded)
/// - PLATFORM    : platform recipient address for the router
/// - CREATOR     : creator recipient address for the router
/// Output:
/// - Prints the deployed router address
/// - Writes JSON to `docs/evidence/day7/router.json` with { address, chain="sepolia" }
contract DeployFeeRouter is Script {
    /// @notice Execute the deployment and write basic evidence artifacts.
    /// @dev Flow: load env → startBroadcast → new FeeRouter(...) → stopBroadcast
    ///           → log address → serialize & write JSON.
    function run() external {
        // ---- Load from .env ----
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address platform = vm.envAddress("PLATFORM");
        address creator = vm.envAddress("CREATOR");

        // ---- Deploy ----
        vm.startBroadcast(pk);
        FeeRouter router = new FeeRouter(platform, creator);
        vm.stopBroadcast();

        // ---- Log to stdout ----
        console2.log("FeeRouter:", address(router));

        // ---- Persist minimal evidence as JSON ----
        string memory root = "router";
        vm.serializeAddress(root, "address", address(router));
        string memory dir = "docs/evidence/day7";
        vm.createDir(dir, true);
        string memory out = vm.serializeString(root, "chain", "sepolia");
        vm.writeJson(out, string.concat(dir, "/router.json"));
    }
}
