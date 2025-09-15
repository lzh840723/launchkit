// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TaxedERC20} from "../contracts/TaxedERC20.sol";

/// @title SetTokenTaxToRouter (Foundry Script)
/// @notice Sets a TaxedERC20's tax rate and tax collector to an existing FeeRouter.
/// @dev Environment (.env) variables:
/// - OWNER_PK : private key of the token owner (authorized to call setTax)
/// - TOKEN    : deployed TaxedERC20 address
/// - ROUTER   : deployed FeeRouter address (to become taxCollector)
/// - BPS      : tax in basis points (e.g., 200 = 2%)
contract SetTokenTaxToRouter is Script {
    /// @notice Broadcast a single `setTax(bps, router)` transaction from the token owner.
    /// @dev Flow: load env → startBroadcast(ownerPk) → setTax → stopBroadcast → log.
    function run() external {
        uint256 ownerPk = vm.envUint("OWNER_PK");      // token owner's private key
        address token   = vm.envAddress("TOKEN");      // deployed TaxedERC20
        address router  = vm.envAddress("ROUTER");     // deployed FeeRouter
        uint16  bps     = uint16(vm.envUint("BPS"));   // e.g., 200 (2%)

        vm.startBroadcast(ownerPk);
        TaxedERC20(token).setTax(bps, router);
        vm.stopBroadcast();

        console2.log("Token setTax ok:", token);
    }
}
