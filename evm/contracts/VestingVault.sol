// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VestingVault
 * @notice 线性释放金库（带 cliff）。支持多次注资累计、按总额线性归属。
 *
 * @dev 业务特性：
 * - 悬崖期（cliff）之前归属为 0；
 * - 悬崖后按 (now - start) / duration 线性归属；
 * - 超过 (start + duration) 后全部归属；
 * - 多次 fund 累计到 totalReceived，统一按同一条曲线释放（不是分批各自曲线）；
 * - beneficiary 或 owner 都可触发 release；amount=0 表示释放全部可释放额度；
 * - 事件：Funded / Released，便于前端与对账。
 *
 * @dev 安全与限制：
 * - onlyOwner 才能 fund（需要先 approve 本合约）；
 * - 使用 SafeERC20 兼容非标准 ERC20；
 * - constructor 校验 cliff ≤ duration；duration=0 代表部署后即可全部归属；
 * - 关键参数设为 immutable，部署后不可更改。
 */
contract VestingVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice 要发放的 ERC20 代币
    IERC20  public immutable token;

    /// @notice 受益人地址（领取者）
    address public immutable beneficiary;

    /// @notice 线性释放起始时间戳（Unix）
    uint64  public immutable start;

    /// @notice 总释放时长（秒）
    uint64  public immutable duration;

    /// @notice 悬崖期时长（从 start 起算，秒）
    uint64  public immutable cliff;

    /// @notice 累计注资总额（所有 fund 之和）
    uint256 public totalReceived;

    /// @notice 累计已释放总额
    uint256 public released;

    /// @notice 注资成功事件（amount 为本次注资额）
    event Funded(uint256 amount);

    /// @notice 释放成功事件（amount 为本次释放额）
    event Released(uint256 amount);

    /**
     * @param _token         要发放的 ERC20
     * @param _beneficiary   受益人
     * @param _start         释放起始时间
     * @param _duration      总释放时长
     * @param _cliff         悬崖期（从 _start 起算）
     * @param _initialOwner  合约 owner 初始地址（通常为多签/项目方）
     *
     * @dev 要求：
     * - _token / _beneficiary 非零地址；
     * - _cliff ≤ _duration（允许 _duration=0，即部署后即可全部归属）；
     */
    constructor(
        IERC20 _token,
        address _beneficiary,
        uint64 _start,
        uint64 _duration,
        uint64 _cliff,
        address _initialOwner
    ) Ownable(_initialOwner) {
        require(address(_token) != address(0), "token=0");
        require(_beneficiary != address(0), "beneficiary=0");
        require(_cliff <= _duration, "cliff>duration");

        token = _token;
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        cliff = _cliff;
    }

    /**
     * @notice owner 注资（调用前需对本合约 approve）
     * @param amount 注资代币数量
     *
     * @dev 多次注资会累计到 totalReceived，按同一释放曲线线性归属。
     *      CEI：先更新状态，再执行外部交互；并用 nonReentrant 防重入。
     */
    function fund(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "amount=0");
        // Effects
        totalReceived += amount;
        // Interactions
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(amount);
    }

    /**
     * @notice 计算某个时间点 ts 的累计归属额度（不考虑已领取）
     * @param ts 时间戳（Unix）
     * @return 已归属的代币总额（<= totalReceived）
     *
     * @dev 规则：
     * - ts < start + cliff    => 0
     * - ts >= start + duration => totalReceived（全部归属）
     * - 其他 => totalReceived * (ts - start) / duration（线性）
     */
    function vestedAmount(uint64 ts) public view returns (uint256) {
        if (ts < start + cliff) return 0;
        if (ts >= start + duration) return totalReceived;
        // 线性插值（uint256 运算，0.8+ 自动检查溢出）
        return (totalReceived * (ts - start)) / duration;
    }

    /**
     * @notice 当前可领取额度（= 已归属 - 已领取，最少为 0）
     */
    function releasable() public view returns (uint256) {
        uint256 vested = vestedAmount(uint64(block.timestamp));
        if (vested <= released) return 0;
        return vested - released;
    }

    /**
     * @notice 领取已归属的代币
     * @param amount 期望领取数量；若为 0 或大于可领取额度，则领取“全部可领取额度”
     *
     * @dev 访问控制：只有 beneficiary 或 owner 可以触发；
     *      CEI：先更新状态（released），再外部交互；并用 nonReentrant 防重入。
     */
    function release(uint256 amount) external nonReentrant {
        require(msg.sender == beneficiary || msg.sender == owner(), "not allowed");

        uint256 avail = releasable();
        require(avail > 0, "nothing to release");

        // amount=0 或超额时，按“全部可领取额度”发放
        uint256 toSend = (amount == 0 || amount > avail) ? avail : amount;

        // Effects
        released += toSend;
        // Interactions
        token.safeTransfer(beneficiary, toSend);
        emit Released(toSend);
    }
}
