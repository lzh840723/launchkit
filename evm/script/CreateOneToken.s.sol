// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {TokenFactory} from "../contracts/TokenFactory.sol";

/// @title CreateOneToken (Foundry Script)
/// @notice Uses an already deployed {TokenFactory} to create a single TaxedERC20.
/// @dev The factory sets tax to 2% (200 bps).
/// Environment variables expected (.env):
/// - TOKEN_FACTORY  : deployed factory address
/// - NAME           : token name
/// - SYMBOL         : token symbol (≤ 11 chars)
/// - DECIMALS       : decimals (6–18)
/// - INITIAL_SUPPLY : initial supply in base units (scaled by 10**DECIMALS)
/// - TOKEN_OWNER    : initial owner & initial mint recipient
/// - PRIVATE_KEY    : broadcaster’s private key (must be funded for gas)
/// Logs printed: factory address, new token address, owner, name/symbol, decimals, supply.
contract CreateOneToken is Script {
    /// @notice Execute the factory call to create one token.
    /// @dev Flow: load env → startBroadcast → factory.createToken(...) → stopBroadcast → log details.
    function run() external {
        // ---- Load from .env ----
        address factoryAddr    = vm.envAddress("TOKEN_FACTORY");   // Deployed factory
        string memory name_    = vm.envString("NAME");             // Token name
        string memory symbol_  = vm.envString("SYMBOL");           // Symbol
        uint8 decimals_        = uint8(vm.envUint("DECIMALS"));    // 6–18
        uint256 initialSupply_ = vm.envUint("INITIAL_SUPPLY");     // Base units (scaled)
        address tokenOwner_    = vm.envAddress("TOKEN_OWNER");     // New token owner / initial recipient
        uint256 pk             = vm.envUint("PRIVATE_KEY");        // Private key for broadcasting

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
