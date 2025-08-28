// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

contract TaxedERC20 is ERC20, ERC20Permit, Ownable, Pausable {
    uint16 public taxBps; // 基点：1% = 100
    address public taxCollector;
    mapping(address => bool) public whitelist;

    // 兼容你原有的事件
    event TaxUpdated(uint16 bps, address collector);
    event WhitelistSet(address indexed acct, bool allowed);

    // 新增的更细粒度事件（测试也会用到）
    event TaxBpsUpdated(uint16 oldBps, uint16 newBps);
    event TaxCollectorUpdated(
        address indexed oldCollector,
        address indexed newCollector
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address owner_,
        uint16 taxBps_,
        address taxCollector_
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(owner_) {
        require(taxBps_ <= 1000, "tax too high"); // <=10%
        taxBps = taxBps_;
        taxCollector = taxCollector_;
        _mint(owner_, initialSupply);
    }

    /// @notice 旧版一次同时设置（保留做兼容；推荐用下面两个新函数）
    function setTax(uint16 bps, address collector) external onlyOwner {
        require(bps <= 1000, "tax too high");
        taxBps = bps;
        taxCollector = collector;
        emit TaxUpdated(bps, collector);
    }

    /// @notice 单独设置税率，上限 10%
    function setTaxBps(uint16 bps) external onlyOwner {
        require(bps <= 1000, "tax too high");
        emit TaxBpsUpdated(taxBps, bps);
        taxBps = bps;
    }

    /// @notice 单独设置收税地址，禁止 zero
    function setTaxCollector(address collector_) external onlyOwner {
        require(collector_ != address(0), "collector = zero");
        emit TaxCollectorUpdated(taxCollector, collector_);
        taxCollector = collector_;
    }

    /// @notice 误转回收（owner-only）
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    function setWhitelist(address acct, bool allowed) external onlyOwner {
        whitelist[acct] = allowed;
        emit WhitelistSet(acct, allowed);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override whenNotPaused {
        if (
            from != address(0) &&
            to != address(0) &&
            !whitelist[from] &&
            !whitelist[to] &&
            taxBps > 0
        ) {
            uint256 fee = (value * taxBps) / 10_000;
            if (fee > 0 && taxCollector != address(0)) {
                super._update(from, taxCollector, fee);
                value -= fee;
            }
        }
        super._update(from, to, value);
    }
}
