// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(); // 搭配 --account deployer 使用

        // 方法1：用环境变量传入
        address owner = vm.envAddress("OWNER");

        // 部署合约
        TokenFactory factory = new TokenFactory(owner);

        // 打印日志
        console2.log("TokenFactory re-deployed at:", address(factory));


        vm.stopBroadcast();
    }
}
