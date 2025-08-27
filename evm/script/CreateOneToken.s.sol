// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

contract CreateOneToken is Script {
    uint256 constant TOTAL_SUPPLY = 1_000_000 ether; // 100万枚（18位）
    uint16  constant TAX_BPS      = 100;             // 1%（基点）

    function run() external {
        vm.startBroadcast(); // 用与工厂 owner 相同的账户广播

        address factoryAddr   = vm.envAddress("TOKEN_FACTORY");
        TokenFactory factory  = TokenFactory(factoryAddr);

        // address taxCollector = vm.envAddress("TAX_COLLECTOR");
        address taxCollector  = vm.envAddress("OWNER");

        address token = factory.createToken(
            "Niannian Token",  // name
            "NIAN",            // symbol
            TOTAL_SUPPLY,      // initialSupply（最小单位）
            TAX_BPS,           // 税率（基点）
            taxCollector       // 收税地址
        );

        console2.log("NEW TOKEN:", token);
        vm.stopBroadcast();
    }
}
