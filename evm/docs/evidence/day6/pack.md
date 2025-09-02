# Day 6 Evidence Pack — TaxedERC20 (Tax / Whitelist / Blacklist / Pause, OZ v5)

## Goals
- Implement an ERC20 with **transfer tax**, **whitelist (tax-exempt)**, **blacklist (blocked)**, and **pause/unpause**, using **OpenZeppelin v5** and the unified `_update` hook.
- Wire the token into **TokenFactory.createToken(...)**.
- Cover the core behaviors with Foundry tests and output a **gas report**.
- Produce a verifiable evidence pack (on-chain addresses, logs, test & gas artifacts).

## What was done
- **Contract**: `contracts/TaxedERC20.sol`
  - Uses `_update(from, to, amount)` to:
    - enforce pause (`_requireNotPaused()` → OZ v5 `EnforcedPause()`),
    - block blacklisted accounts,
    - apply basis-point tax unless either party is whitelisted or the transfer is mint/burn,
    - forward the tax to `taxCollector`, and send the net to the recipient.
  - Owner functions: `setTax(uint16 bps, address collector)`, `setWhitelist(address,bool)`, `setBlacklist(address,bool)`, `pause()`, `unpause()`.
  - Custom decimals via an internal `_decimals` value and `override decimals()`.
- **Factory**: `contracts/TokenFactory.sol`
  - `createToken(...)` now deploys `TaxedERC20` (keeps the event fields for name/symbol/decimals/initialSupply/owner).
- **Tests**: `test/TaxedERC20.t.sol`
  - Transfer tax goes to collector; whitelist exempts tax; blacklist blocks; pause blocks; owner-only checks; decimals & initial mint assertions.
- **Scripts**: `script/CreateOneToken.s.sol` used to deploy via factory.
- **Reports**:
  - `reports/deploy-day6.txt` (script traces & addresses),
  - `reports/gas-day6.txt` (gas report).

## On-chain (Sepolia)
- **Factory**: `0x09139374cb2aBFb3f989D1FC12F83905f01f1B5c`
- **Token**: `0x88b5DC0B57605A552716a1591b39965085cb8Eb1`
- **Owner**: `0x0297C0Df7FdB329676711B4958FEAA33aE9633aB`

### Quick self-check commands
```bash
# Basic metadata
cast call $NEW_TOKEN "name()(string)"         --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "symbol()(string)"       --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "decimals()(uint8)"      --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "totalSupply()(uint256)" --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "owner()(address)"       --rpc-url $SEPOLIA_RPC_URL

# (If exposed) tax configuration
# cast call $NEW_TOKEN "taxBps()(uint16)"        --rpc-url $SEPOLIA_RPC_URL
# cast call $NEW_TOKEN "taxCollector()(address)" --rpc-url $SEPOLIA_RPC_URL
```

## Artifacts

* `docs/evidence/day6/deploy-day6.txt` — full forge script logs
* `docs/evidence/day6/gas-day6.txt` — gas report
* (Optional) screenshots:

  * `forge test -vvv` green checks for `TaxedERC20.t.sol`
  * `TokenCreated` event with deployed token address

## Test summary

* Factory unit tests: passing
* Factory integration test(s): passing
* `TaxedERC20.t.sol`:

  * **Tax path:** fee goes to `taxCollector`, recipient receives `amount - fee`
  * **Whitelist:** exempt from tax
  * **Blacklist:** transfers revert with custom error
  * **Pause:** transfers revert with `EnforcedPause()` (OZ v5)
  * **Owner-only guards** and **decimals & initial mint** checks

> See `reports/gas-day6.txt` for gas stats.

## CI Evidence
- Run URL: https://github.com/lzh840723/launchkit/actions/runs/17412510720
- Artifacts: `docs/evidence/day6/gas-ci.txt`
- Logs: `docs/evidence/day6/ci-run.log`
