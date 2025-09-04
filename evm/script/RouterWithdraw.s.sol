// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {FeeRouter} from "../contracts/FeeRouter.sol";

contract RouterWithdraw is Script {
    function run() external {
        uint256 pk   = vm.envUint("PRIVATE_KEY");
        address r    = vm.envAddress("ROUTER");
        address token= vm.envAddress("TOKEN");

        vm.startBroadcast(pk);
        FeeRouter(r).withdraw(token);
        vm.stopBroadcast();
    }
}
