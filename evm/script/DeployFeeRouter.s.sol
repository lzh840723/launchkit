// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

contract DeployFeeRouter is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address platform = vm.envAddress("PLATFORM");
        address creator = vm.envAddress("CREATOR");

        vm.startBroadcast(pk);
        FeeRouter router = new FeeRouter(platform, creator);
        vm.stopBroadcast();

        console2.log("FeeRouter:", address(router));

        string memory root = "router";
        vm.serializeAddress(root, "address", address(router));
        string memory dir = "docs/evidence/day7";
        vm.createDir(dir, true);
        string memory out = vm.serializeString(root, "chain", "sepolia");
        vm.writeJson(out, string.concat(dir, "/router.json"));
    }
}
