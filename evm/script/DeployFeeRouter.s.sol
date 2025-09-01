// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import "../contracts/TokenFactory.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(pk);

        vm.startBroadcast(pk);
        TokenFactory factory = new TokenFactory(admin);
        vm.stopBroadcast();

        console2.log("TokenFactory:", address(factory));
    }
}
