// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

contract CreateOneToken is Script {
    function run() external {
        // 从 .env 里读取 PRIVATE_KEY（Foundry 默认）
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(pk);

        // 已部署的工厂地址：若你没有，就部署一个
        address factoryAddr = vm.envOr("TOKEN_FACTORY", address(0));
        TokenFactory factory = factoryAddr == address(0)
            ? new TokenFactory(owner)
            : TokenFactory(factoryAddr);

        // 演示：打开工厂（对外可调用）
        factory.setOpen(true);

        address token = factory.createToken("MyToken", "MYT", 18, 1e18, owner);

        vm.stopBroadcast();

        console2.log("Factory:", address(factory));
        console2.log("Token:", token);
    }
}
