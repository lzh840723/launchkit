// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(); // 搭配 --account deployer 使用

        // 方法1：用环境变量传入
        address owner = vm.envAddress("OWNER");

        // 方法2：直接写死你的地址（更简单）
        // address owner = 0x0297C0Df7FdB329676711B4958FEAA33aE9633aB;

        TokenFactory factory = new TokenFactory(owner);
        console2.log("TokenFactory re-deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
