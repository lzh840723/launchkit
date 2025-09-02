// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

/// @notice 通过已部署的 Factory 创建 1 个 TaxedERC20（Factory 内部固定 2% 税）
contract CreateOneToken is Script {
    function run() external {
        // ---- 读取 .env ----
        address factoryAddr   = vm.envAddress("TOKEN_FACTORY");   // 工厂地址（已部署）
        string memory name_   = vm.envString("NAME");              // 代币名
        string memory symbol_ = vm.envString("SYMBOL");            // 符号
        uint8 decimals_       = uint8(vm.envUint("DECIMALS"));     // 6~18
        uint256 initialSupply_= vm.envUint("INITIAL_SUPPLY");      // 按 decimals_ 计
        address tokenOwner_   = vm.envAddress("TOKEN_OWNER");      // 新代币 owner/接收初始量
        uint256 pk            = vm.envUint("PRIVATE_KEY");         // 发送交易用私钥

        vm.startBroadcast(pk);
        address newToken = TokenFactory(factoryAddr).createToken(
            name_,
            symbol_,
            decimals_,
            initialSupply_,
            tokenOwner_
        );
        vm.stopBroadcast();

        console2.log("Factory  :", factoryAddr);
        console2.log("Token    :", newToken);
        console2.log("Owner    :", tokenOwner_);
        console2.log("Name/Sym :", name_, symbol_);
        console2.log("Decimals :", decimals_);
        console2.log("Supply   :", initialSupply_);
    }
}
