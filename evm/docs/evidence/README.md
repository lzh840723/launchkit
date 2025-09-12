# Evidence Index (Detailed)

All delivery proofs for the **EVM Launchkit** — CI logs, gas reports, deploy runs, verification links, and security hardening.

> **Demo video**  
> EVM Launchkit — Deploy & Verify on Sepolia (Foundry)  
> **https://youtu.be/bUFz8v6JHiw**

---

## Day4 — CI (Green)
- ✅ **Overview:** [`day4/evidence-ci.md`](./day4/evidence-ci.md)
- 🖼️ CI green screenshots:
  - [`day4/img/ci-green-1.png`](./day4/img/ci-green-1.png)
  - [`day4/img/ci-green-2.png`](./day4/img/ci-green-2.png)

---

## Day5 — Evidence Pack #1
- 📦 Pack: [`day5/pack.md`](./day5/pack.md)
- 📈 Gas (CI artifact): [`day5/gas-ci.txt`](./day5/gas-ci.txt)
- 🖼️ CI green: [`day5/ci-green-1.png`](./day5/ci-green-1.png)

---

## Day6 — TaxedERC20 (OZ v5)
- 📦 Pack: [`day6/pack.md`](./day6/pack.md)
- 🧪 CI run (full): [`day6/ci-run.log`](./day6/ci-run.log)
- 📈 Gas (local + CI):
  - [`day6/gas-day6.txt`](./day6/gas-day6.txt)
  - [`day6/gas-ci.txt`](./day6/gas-ci.txt) (and archive [`day6/gas-ci.zip`](./day6/gas-ci.zip))
- 🚀 Deploy log (Day6): [`day6/deploy-day6.txt`](./day6/deploy-day6.txt)
- 🧰 CI step-by-step artifacts (txt):
  - [`day6/ci-logs/test/1_Set%20up%20job.txt`](./day6/ci-logs/test/1_Set%20up%20job.txt)
  - [`day6/ci-logs/test/2_Checkout.txt`](./day6/ci-logs/test/2_Checkout.txt)
  - [`day6/ci-logs/test/3_Setup%20Foundry.txt`](./day6/ci-logs/test/3_Setup%20Foundry.txt)
  - [`day6/ci-logs/test/4_Install%20dependencies%20%28explicit%29.txt`](./day6/ci-logs/test/4_Install%20dependencies%20%28explicit%29.txt)
  - [`day6/ci-logs/test/5_Run%20tests.txt`](./day6/ci-logs/test/5_Run%20tests.txt)
  - [`day6/ci-logs/test/6_Gas%20report%20%28artifact%29.txt`](./day6/ci-logs/test/6_Gas%20report%20%28artifact%29.txt)
  - [`day6/ci-logs/test/7_Upload%20gas%20report.txt`](./day6/ci-logs/test/7_Upload%20gas%20report.txt)
  - [`day6/ci-logs/test/8_Attach%20gas%20to%20summary.txt`](./day6/ci-logs/test/8_Attach%20gas%20to%20summary.txt)
  - [`day6/ci-logs/test/15_Post%20Setup%20Foundry.txt`](./day6/ci-logs/test/15_Post%20Setup%20Foundry.txt)
  - [`day6/ci-logs/test/16_Post%20Checkout.txt`](./day6/ci-logs/test/16_Post%20Checkout.txt)
  - [`day6/ci-logs/test/17_Complete%20job.txt`](./day6/ci-logs/test/17_Complete%20job.txt)
  - [`day6/ci-logs/test/system.txt`](./day6/ci-logs/test/system.txt)
- 🗜️ CI logs archive: [`day6/ci-logs.zip`](./day6/ci-logs.zip)

**What this proves**
- Contracts built on **OpenZeppelin v5** with tax/whitelist/blacklist/pause via the unified `_update` hook.
- Complete CI: compile, tests, gas report generation, and artifact upload.

---

## Day7 — Router Verified (Tax Routing)
- 🔗 Verify links index: [`day7/verify-links.md`](./day7/verify-links.md)
- 📮 Deployed addresses: [`day7/addresses.json`](./day7/addresses.json)
- 🧩 Router artifact: [`day7/router.json`](./day7/router.json)
- ⚙️ Token tax config: [`day7/token-tax.json`](./day7/token-tax.json)
- 🧾 Transactions: [`day7/txs.md`](./day7/txs.md)
- 💸 Withdraw result: [`day7/withdraw.json`](./day7/withdraw.json)
- ▶️ Script run receipts:
  - Deploy Router: [`day7/deploy-router-run.json`](./day7/deploy-router-run.json)
  - Set Tax: [`day7/set-tax-run.json`](./day7/set-tax-run.json)
  - Withdraw: [`day7/withdraw-run.json`](./day7/withdraw-run.json)
- 📈 Gas (router day): [`day7/gas-day7.txt`](./day7/gas-day7.txt)
- 🖥️ Demo log: [`day7/demo.log`](./day7/demo.log)

**What this proves**
- Tax can be routed to an external contract; deploy/config/withdraw have both on-chain and log evidence; stable gas figures.

---

## Day8 — VestingVault & Minimal Frontend
- 🔗 Verify links: [`day8/verify-links.md`](./day8/verify-links.md)
- 📮 Addresses: [`day8/addresses.json`](./day8/addresses.json)
- 📦 Evidence pack: [`day8/pack.md`](./day8/pack.md)
- 📜 Vesting params: [`day8/vesting.json`](./day8/vesting.json)
- ▶️ Vesting run receipt: [`day8/vesting-run.json`](./day8/vesting-run.json)
- 🧾 Transactions: [`day8/txs.md`](./day8/txs.md)
- 📈 Gas: [`day8/gas-day8.txt`](./day8/gas-day8.txt)

**What this proves**
- VestingVault functionality is live; a minimal frontend supports the main flow (connect, query releasable, claim).

---

## Day9 — Slither Hardening (Static Analysis)
- 🧭 Summary: [`day9/summary.md`](./day9/summary.md)
- 🔍 Before:
  - [`day9/slither-before.md`](./day9/slither-before.md)
  - [`day9/slither-before.json`](./day9/slither-before.json)
- ✅ After:
  - [`day9/slither-after.md`](./day9/slither-after.md)
  - [`day9/slither-after.json`](./day9/slither-after.json)
- 📑 Diff: [`day9/slither-diff.md`](./day9/slither-diff.md)

**What this proves**
- Introduces Slither static analysis; issues identified → fixed → re-verified, with before/after reports and a diff.

---

## Tips

- **Gas:** In the root repo CI (`Actions → ci`), download `gas-ci.txt`. Locally, reproduce with `forge test -vvv --gas-report`.
- **Verification:** Etherscan/Blockscout links are consolidated in each day’s `verify-links.md` / `addresses.json`.
- **Demo flow:** Watch the demo video first (top of this page), then drill into Day6/7/8 links for details.
