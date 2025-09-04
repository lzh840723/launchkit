// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {VestingVault} from "../contracts/VestingVault.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

/**
 * @title VestingVaultTest
 * @notice 业务向单测：验证带 cliff 的线性释放金库在关键时间点与角色权限上的行为是否符合预期
 *
 * 覆盖场景：
 * 1) cliff 前不可领取（归属=0）；
 * 2) cliff 之后线性归属：中途可部分领取，期末全部归属并领完为 0；
 * 3) 只有 owner 能注资（需先 approve，再 fund）；
 * 4) 受益人和 owner 都可触发 release（amount=0 表示领取全部可领取额度）。
 */
contract VestingVaultTest is Test {
    // 用你项目里的 TaxedERC20 作为被发放代币（这里把税率设为 0，避免干扰）
    TaxedERC20 token;

    // 待测的线性释放金库
    VestingVault vault;

    // 关键角色
    address owner = address(0xA11CE); // 合约/金库的运营方（多签/项目方）
    address bene  = address(0xB0B);   // 受益人（领取者）

    // 代币规格
    uint8   decs   = 18;
    uint256 supply = 1_000_000 * 1e18;

    function setUp() public {
        /**
         * 部署一个简单的 ERC-20 作为被发放代币：
         * name="T", symbol="T", decimals=18, supply 铸给 owner，税率=0，collector=owner
         * 注：这里选用项目已有的 TaxedERC20 便于集成，生产中也可替换为标准 ERC20。
         */
        token = new TaxedERC20("T", "T", decs, supply, owner, 0, owner);

        // 时间参数：100 秒后开始线性释放；总时长 30 天；cliff 为 7 天
        uint64 start    = uint64(block.timestamp) + 100;
        uint64 duration = 30 days;
        uint64 cliff    = 7 days;

        // 部署金库；初始 owner=owner，受益人为 bene
        vault = new VestingVault(
            token,
            bene,
            start,
            duration,
            cliff,
            owner
        );

        // 让 owner 成为白名单，避免 TaxedERC20 的税/风控对测试造成影响
        vm.prank(owner);
        token.setWhitelist(owner, true);
    }

    /**
     * @dev 辅助：模拟 owner 完成 approve + fund 的标准注资流程
     */
    function _fund(uint256 amt) internal {
        vm.startPrank(owner);
        token.approve(address(vault), amt); // 先授权金库可划转
        vault.fund(amt);                    // 再由 owner 注资
        vm.stopPrank();
    }

    /**
     * @notice 业务主流程：cliff 前不可领；cliff 后线性可领；中途领一半；期末领清为 0
     */
    function test_flow_linear_with_cliff() public {
        uint256 amt = 100_000 * 1e18;
        _fund(amt); // 累计注资 10 万枚

        // 1) cliff 前：不可领取
        vm.warp(vault.start() + vault.cliff() - 1);
        assertEq(vault.releasable(), 0, "should be 0 before cliff");

        // 2) cliff 后 + 1 天：已产生线性归属额度
        vm.warp(vault.start() + vault.cliff() + 1 days);
        uint256 midAvail = vault.releasable();
        assertGt(midAvail, 0, "should be >0 after cliff");

        // 3) 受益人领取“一半”的可领取额度
        vm.prank(bene);
        vault.release(midAvail / 2);
        assertEq(token.balanceOf(bene), midAvail / 2, "beneficiary should receive half");

        // 4) 推进到期末：应有剩余可领取（= 全额归属 - 已领取）
        vm.warp(vault.start() + vault.duration());
        uint256 tail = vault.releasable();
        assertGt(tail, 0, "should be >0 at end");

        // 5) owner 也可触发 release，amount=0 表示“把可领的全部领完”
        vm.prank(owner);
        vault.release(0);

        // 6) 全部领完后，可领取额度应为 0；受益人余额=中途一半 + 末期剩余
        assertEq(vault.releasable(), 0, "should be 0 after final release");
        assertEq(token.balanceOf(bene), (midAvail / 2) + tail, "beneficiary should receive all vested tokens");
    }

    /**
     * @notice 只有 owner 才能注资；owner 必须按 ERC-20 流程先 approve 再 fund
     */
    function test_onlyOwner_can_fund() public {
        // 非 owner 调用应 revert
        vm.expectRevert();
        vault.fund(1e18);

        // owner 走标准流程：approve + fund
        _fund(1e18);
        assertEq(vault.totalReceived(), 1e18, "totalReceived should match funded amount");
    }
}
