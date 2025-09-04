// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

contract SetTokenTaxToRouter is Script {
    function run() external {
        uint256 ownerPk = vm.envUint("OWNER_PK");           // token owner 的私钥
        address token   = vm.envAddress("TOKEN");           // 已部署的 TaxedERC20
        address router  = vm.envAddress("ROUTER");          // 已部署的 FeeRouter
        uint16  bps     = uint16(vm.envUint("BPS"));        // 一般=200

        vm.startBroadcast(ownerPk);
        TaxedERC20(token).setTax(bps, router);
        vm.stopBroadcast();

        console2.log("Token setTax ok:", token);
    }
}
