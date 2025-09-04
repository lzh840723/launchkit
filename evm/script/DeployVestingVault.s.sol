// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {VestingVault} from "../contracts/VestingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployVestingVault
 * @notice 部署脚本：在 Sepolia 上部署 VestingVault，并完成首次注资
 *
 * 业务流程：
 * 1. 从环境变量读取参数（私钥、代币地址、受益人、时间参数、初始注资数量）
 * 2. 使用部署者地址作为 owner 创建 VestingVault
 * 3. 部署者先对 Vault 授权，再调用 fund() 完成首次注资
 * 4. 导出结果到 JSON 文件，作为证据包存档
 */
contract DeployVestingVault is Script {
    function run() external {
        // === 读取环境变量 ===
        uint256 pk = vm.envUint("PRIVATE_KEY");                // 部署/注资的私钥
        address token = vm.envAddress("TOKEN");                // 要锁仓的代币
        address bene  = vm.envAddress("VESTING_BENEFICIARY");  // 受益人
        uint64  start = uint64(vm.envUint("VESTING_START"));   // 释放起始时间戳
        uint64  dur   = uint64(vm.envUint("VESTING_DURATION"));// 总时长
        uint64  cliff = uint64(vm.envUint("VESTING_CLIFF"));   // 悬崖期
        uint256 amt   = vm.envUint("VESTING_AMOUNT");          // 首次注资数量

        // === 广播交易 ===
        vm.startBroadcast(pk);

        // 1) 部署 VestingVault，owner=部署者
        VestingVault vault = new VestingVault(
            IERC20(token),
            bene,
            start,
            dur,
            cliff,
            vm.addr(pk)
        );
        console2.log("VestingVault deployed at:", address(vault));

        // 2) 首次注资：先授权，再 fund
        IERC20(token).approve(address(vault), amt);
        vault.fund(amt);

        vm.stopBroadcast();

        // === 导出结果 JSON ===
        string memory out = vm.serializeAddress("", "vault", address(vault));
        out = vm.serializeAddress(out, "token", token);
        out = vm.serializeAddress(out, "beneficiary", bene);
        out = vm.serializeUint(out, "amount", amt);
        out = vm.serializeString(out, "chain", "sepolia");
        vm.writeJson(out, "docs/evidence/day8/vesting.json");
    }
}
