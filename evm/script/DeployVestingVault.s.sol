// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {VestingVault} from "../contracts/VestingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployVestingVault
 * @notice Deployment script: deploy a {VestingVault} on Sepolia and perform an initial funding.
 *
 * @dev Expected environment variables (.env):
 * - PRIVATE_KEY        : deployer/funder private key (must be funded)
 * - TOKEN              : ERC20 token address to vest
 * - VESTING_BENEFICIARY: beneficiary address
 * - VESTING_START      : vesting start timestamp (unix seconds)
 * - VESTING_DURATION   : total vesting duration (seconds)
 * - VESTING_CLIFF      : cliff length (seconds)
 * - VESTING_AMOUNT     : initial funding amount (base units)
 *
 * Process:
 *  1) Read parameters from environment variables.
 *  2) Deploy {VestingVault} with the deployer as owner.
 *  3) Approve the vault and call `fund()` for the initial deposit.
 *  4) Write a JSON artifact to be included in the evidence pack.
 */
contract DeployVestingVault is Script {
    function run() external {
        // === Load environment variables ===
        uint256 pk = vm.envUint("PRIVATE_KEY");                // deploy/fund private key
        address token = vm.envAddress("TOKEN");                // ERC20 to be vested
        address bene  = vm.envAddress("VESTING_BENEFICIARY");  // beneficiary
        uint64  start = uint64(vm.envUint("VESTING_START"));   // start timestamp
        uint64  dur   = uint64(vm.envUint("VESTING_DURATION"));// total duration
        uint64  cliff = uint64(vm.envUint("VESTING_CLIFF"));   // cliff length
        uint256 amt   = vm.envUint("VESTING_AMOUNT");          // initial funding amount

        // === Broadcast transactions ===
        vm.startBroadcast(pk);

        // 1) Deploy VestingVault, owner = deployer
        VestingVault vault = new VestingVault(
            IERC20(token),
            bene,
            start,
            dur,
            cliff,
            vm.addr(pk)
        );
        console2.log("VestingVault deployed at:", address(vault));

        // 2) Initial funding: approve, then fund
        IERC20(token).approve(address(vault), amt);
        vault.fund(amt);

        vm.stopBroadcast();

        // === Write JSON artifact ===
        string memory out = vm.serializeAddress("", "vault", address(vault));
        out = vm.serializeAddress(out, "token", token);
        out = vm.serializeAddress(out, "beneficiary", bene);
        out = vm.serializeUint(out, "amount", amt);
        out = vm.serializeString(out, "chain", "sepolia");
        vm.writeJson(out, "docs/evidence/day8/vesting.json");
    }
}
