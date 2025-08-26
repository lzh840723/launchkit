# Day 2 Deliverable (No FeeRouter Variant)

> Mainline: `TokenFactory (Ownable)` + `TaxedERC20 (taxBps + taxCollector)`
> Toolchain: Solidity `0.8.24`, EVM `paris`, Foundry/Forge

## ✅ What’s Done Today

* [x] Scaffolding cleanup: removed `Counter.*`
* [x] Tests:

  * `test/TaxedERC20.t.sol`: tax deduction, whitelist no-tax, pause protection, `transferFrom`, tax destination
  * `test/Factory.t.sol`: owner-only creation, 100% initial supply to owner
* [x] Reports: `reports/gas-day2.txt`, `reports/coverage-day2.txt`, `reports/slither-day2.txt`
* [x] Deployment script stub: `script/DeployFactory.s.sol`
* [x] This document

---

## 🧪 Test Results (All Green)

* Suites: 2; Tests: 7; **Passed: 7 / 7**; Failed: 0; Skipped: 0

Key verifications:

* **3% tax**: `10 → 9.7 / 0.3` (receiver / fee collector)
* **Whitelist no-tax**: transfers exempt after owner whitelists address
* **Pause guard**: `transfer` reverts after `pause()`
* **Factory access**: only owner can `createToken`
* **Initial supply**: 100% minted to token owner (the `owner()` passed to constructor)

Command (saved to `reports/gas-day2.txt`):

```bash
forge test --gas-report -vv | tee reports/gas-day2.txt
```

---

## ⛽ Gas Report (Excerpts)

### contracts/TaxedERC20.sol\:TaxedERC20

* **Deployment Cost**: `1,404,600` gas (size `8267` bytes)

| Function       |    Min |    Avg | Median |    Max | # Calls |
| -------------- | -----: | -----: | -----: | -----: | ------: |
| `approve`      | 46,394 | 46,394 | 46,394 | 46,394 |       1 |
| `balanceOf`    |  2,651 |  2,651 |  2,651 |  2,651 |       9 |
| `owner`        |  2,409 |  2,409 |  2,409 |  2,409 |       4 |
| `pause`        | 27,736 | 27,736 | 27,736 | 27,736 |       1 |
| `setWhitelist` | 47,632 | 47,734 | 47,734 | 47,836 |       2 |
| `totalSupply`  |  2,349 |  2,349 |  2,349 |  2,349 |       1 |
| `transfer`     | 24,105 | 60,466 | 55,966 | 85,553 |       5 |
| `transferFrom` | 86,636 | 86,636 | 86,636 | 86,636 |       1 |

### contracts/TokenFactory.sol\:TokenFactory

* **Deployment Cost**: `2,069,796` gas (size `9519` bytes)

| Function      |    Min |     Avg |  Median |       Max | # Calls |
| ------------- | -----: | ------: | ------: | --------: | ------: |
| `createToken` | 25,812 | 659,300 | 659,300 | 1,292,788 |       2 |

> The tables above are the actual output from this run of `forge test --gas-report`.

---

## ✅ Coverage (via `forge coverage`)

> Full report in `reports/coverage-day2.txt`. Summary of key files:

| File                         |            % Lines |   % Statements |   % Branches |       % Funcs |
| ---------------------------- | -----------------: | -------------: | -----------: | ------------: |
| `contracts/TaxedERC20.sol`   | **70.83%** (17/24) | 82.76% (24/29) | 50.00% (3/6) |  66.67% (4/6) |
| `contracts/TokenFactory.sol` |  **100.00%** (4/4) |  100.00% (4/4) |            — | 100.00% (1/1) |

> Note: Router-related files are parked in `_wip/` and excluded from analysis to keep mainline coverage representative.

---

## 🔎 Slither Static Analysis

Command (saved to `reports/slither-day2.txt`):

```bash
slither . --config-file slither.config.json | tee reports/slither-day2.txt
```

Result: **0 High / 0 Medium**. There are **2 informational** findings:

* `TaxedERC20` missing zero-address checks for:

  * constructor param `taxCollector_`
  * `setTax(uint16,address)` param `collector`
    *Reference: Missing zero-address validation*

> Planned fix: add `require(collector != address(0), "collector zero")` in both constructor and `setTax`. Re-run Slither after the patch to confirm.

---

## 🧭 Repro Steps

```bash
# 1) Tests + gas table
forge test --gas-report -vv | tee reports/gas-day2.txt

# 2) Coverage
forge coverage | tee reports/coverage-day2.txt

# 3) Slither (filters third-party, build artifacts, and _wip)
slither . --config-file slither.config.json | tee reports/slither-day2.txt
# or:
# slither . --filter-paths "lib|out|_wip" --exclude solc-version,naming-convention,pragma | tee reports/slither-day2.txt
```

---

## 📦 Day 2 Artifacts

* Code: `contracts/TaxedERC20.sol`, `contracts/TokenFactory.sol`
* Tests: `test/TaxedERC20.t.sol`, `test/Factory.t.sol`
* Script: `script/DeployFactory.s.sol`
* Reports: `reports/gas-day2.txt`, `reports/coverage-day2.txt`, `reports/slither-day2.txt`
* Config: `foundry.toml`, `slither.config.json` (`filter_paths: lib|out|_wip`)
* Docs: `docs/day2.md` (this file)

---

## 🗓️ What’s Next (Day 3)

1. Prepare `.env`: `PRIVATE_KEY`, `SEPOLIA_RPC_URL`, `ETHERSCAN_API_KEY`
2. Deploy & verify Factory:
   `forge script script/DeployFactory.s.sol --rpc-url ... --broadcast --verify`
3. Mint a token via `cast send createToken(...)` and `forge verify-contract` for that token
4. Produce `docs/day3.md` and `reports/deploy-day3.txt` with addresses and verification links

---