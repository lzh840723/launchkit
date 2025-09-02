// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY"); // 从 .env 读私钥
        address owner = vm.envAddress("OWNER"); // 目标 owner（你 .env 里已有）

        vm.startBroadcast(pk); // ✅ 用私钥广播
        TokenFactory f = new TokenFactory(owner); // 若构造不收 owner，就改成 new TokenFactory();
        // 如果构造不收 owner，就在下一行补： f.transferOwnership(owner);

        console2.log("TokenFactory re-deployed at:", address(f));
        vm.stopBroadcast();
    }
}
