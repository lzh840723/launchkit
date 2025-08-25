// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TaxedERC20} from "./TaxedERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract TokenFactory is Ownable {
    event TokenCreated(address token, string name, string symbol);

    constructor(address owner_) Ownable(owner_) {}

    function createToken(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint16 taxBps,
        address taxCollector
    ) external onlyOwner returns (address) {
        TaxedERC20 t = new TaxedERC20(name_, symbol_, initialSupply, owner(), taxBps, taxCollector);
        emit TokenCreated(address(t), name_, symbol_);
        return address(t);
    }
}
