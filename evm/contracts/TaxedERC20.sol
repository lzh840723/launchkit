// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/utils/Pausable.sol";

contract TaxedERC20 is ERC20, ERC20Permit, Ownable, Pausable {
    uint16 public taxBps; // 基点：1% = 100
    address public taxCollector;
    mapping(address => bool) public whitelist;

    event TaxUpdated(uint16 bps, address collector);
    event WhitelistSet(address indexed acct, bool allowed);

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

    function setTax(uint16 bps, address collector) external onlyOwner {
        require(bps <= 1000, "tax too high");
        taxBps = bps;
        taxCollector = collector;
        emit TaxUpdated(bps, collector);
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

    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        if (from != address(0) && to != address(0) && !whitelist[from] && !whitelist[to] && taxBps > 0) {
            uint256 fee = (value * taxBps) / 10_000;
            if (fee > 0 && taxCollector != address(0)) {
                super._update(from, taxCollector, fee);
                value -= fee;
            }
        }
        super._update(from, to, value);
    }
}
