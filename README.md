# Repos Collection — Web3/Blockchain MVPs

A collection of independent MVP projects showcasing skills in Web3/Blockchain development.
Each subfolder is standalone; detailed docs live in each project’s own README.

## Repository Map

* **evm** — **EVM Launchkit (Foundry)**: token factory, tax-enabled ERC20, tests, CI & evidence
* **audit\_docker\_mvp** — Smart-contract automated auditing MVP
* **defi-audit** — Security analysis tools for DeFi protocols
* **nft-query** — NFT metadata & transaction query tools
* **token\_api** — Token data query & management API

> This collection demonstrates backend engineering, on-chain interaction, security auditing, and DevEx.

---

## Demo Videos

### 1) EVM Launchkit — Deploy & Verify on Sepolia (Foundry)

* Compile → Deploy (cast) → Constructor args → Etherscan **Exact Match** → Read checks
* **Watch:** [https://youtu.be/bUFz8v6JHiw](https://youtu.be/bUFz8v6JHiw)
  [![Watch the demo](https://img.youtube.com/vi/bUFz8v6JHiw/hqdefault.jpg)](https://youtu.be/bUFz8v6JHiw)

### 2) Token API — End-to-End (Docker, JWT, Postman)

* Build & start with Docker Compose → Check DB & logs → Generate JWT → Call API with Postman
  → Verify latency (\~1s; cached requests instant) → Confirm logs & DB updates
* **Watch:** [https://youtu.be/bJQyXpvDhhg](https://youtu.be/bJQyXpvDhhg)

---

## Featured: EVM Launchkit (Foundry)

[![CI](https://github.com/lzh840723/launchkit/actions/workflows/ci.yml/badge.svg)](https://github.com/lzh840723/launchkit/actions/workflows/ci.yml)

**What it is**
A practical Foundry template focused on delivery and evidence: token factory + tax-enabled ERC20 (OZ v5), scripts, tests, CI, and reproducible artifacts.

**CI & Gas Evidence**

* **Workflow:** GitHub Actions runs `forge test -vvv` and publishes a gas report (`--gas-report`).
* **Artifacts:** Each run uploads `gas-ci.txt` (downloadable).
* **Scope:** CI runs in the `evm/` subfolder via `defaults.run.working-directory: evm`.

**Quickstart (Sepolia)**

```bash
# inside ./evm
set -a && source .env && set +a
forge build --build-info

# deploy with cast (robust path)
OWNER_ENV="${TOKEN_OWNER:-$INITIAL_OWNER}"
BYTECODE=$(forge inspect contracts/TaxedERC20.sol:TaxedERC20 bytecode)
TX=$(cast send --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY" \
  --create "$BYTECODE" \
  "constructor(string,string,uint8,uint256,address,uint16,address)" \
  "$NAME" "$SYMBOL" $DECIMALS $INITIAL_SUPPLY "$OWNER_ENV" $TAX_BPS "$TAX_COLLECTOR")
NEW_TOKEN=$(echo "$TX" | awk '/^contractAddress/ {print $2}')

# verify
ARGS=$(cast abi-encode "constructor(string,string,uint8,uint256,address,uint16,address)" \
  "$NAME" "$SYMBOL" $DECIMALS $INITIAL_SUPPLY "$OWNER_ENV" $TAX_BPS "$TAX_COLLECTOR")
forge verify-contract --chain sepolia --constructor-args "$ARGS" \
  --etherscan-api-key "$ETHERSCAN_API_KEY" "$NEW_TOKEN" \
  contracts/TaxedERC20.sol:TaxedERC20 --watch
```

**Evidence Packs**

* Day4: [Evidence (CI)](./evm/docs/evidence/day4/evidence-ci.md)
* Day5: [Evidence Pack #1](./evm/docs/evidence/day5/pack.md)
* **Day6**: [Evidence Pack — TaxedERC20 (OZ v5)](./evm/docs/evidence/day6/pack.md)
* **Day7** (Router Verified):

  * [verify-links.md](./evm/docs/evidence/day7/verify-links.md)
  * [addresses.json](./evm/docs/evidence/day7/addresses.json)
  * [router.json](./evm/docs/evidence/day7/router.json)
  * [token-tax.json](./evm/docs/evidence/day7/token-tax.json)
  * [txs.md](./evm/docs/evidence/day7/txs.md)
  * [withdraw.json](./evm/docs/evidence/day7/withdraw.json)
  * [deploy-router-run.json](./evm/docs/evidence/day7/deploy-router-run.json)
  * [set-tax-run.json](./evm/docs/evidence/day7/set-tax-run.json)
  * [withdraw-run.json](./evm/docs/evidence/day7/withdraw-run.json)
  * [gas-day7.txt](./evm/docs/evidence/day7/gas-day7.txt)

---

## Productized Services (Fixed Scope)

* **#1 – Token Factory (simple ERC20)**
  Delivery: factory contract, scripts, tests, gas report, usage notes.

* **#2 – TaxedERC20 (OZ v5)** — tax / whitelist / blacklist / pause
  Delivery: ERC20 with tax via `_update` hook, owner controls, tests, gas report, evidence pack.
  Evidence: see Day6 pack above.

> For service details or custom extensions, please open an issue or contact me.

---

### Notes

* Testnet keys are for demo only. Do **not** reuse on mainnet.
* Some screenshots/links reference the `evm/` submodule and CI artifacts.
