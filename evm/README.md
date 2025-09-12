# EVM Launchkit (Foundry)

A compact Launchkit for shipping ERC20 tokens and a factory, built with **Foundry** + **OpenZeppelin v5**.  
Includes CI, tests, gas reports, and ready-to-use scripts.

🎥 **Demo (Sepolia, Foundry):** https://youtu.be/bUFz8v6JHiw  
[![Watch the demo](https://img.youtube.com/vi/bUFz8v6JHiw/hqdefault.jpg)](https://youtu.be/bUFz8v6JHiw)

---

## What’s inside

- **TokenFactory** — deploy ERC20 tokens with guardrails & event logs  
- **TaxedERC20** — ERC20 with:
  - transfer **tax (bps)** to a **collector**
  - **whitelist** (tax-exempt) & **blacklist** (blocked)
  - **pause/unpause** via OZ v5 unified `_update` with `EnforcedPause()`
  - custom **decimals**
- **Tests** — Foundry unit/integration, `--gas-report`  
- **Scripts** — deploy factory & create token  
- **Evidence** — on-chain addresses, logs, gas, and test artifacts

---

## Quickstart

```bash
# 1) Install deps
forge install

# 2) Env (fill .env)
# PRIVATE_KEY=0x...
# SEPOLIA_RPC_URL=...
# ETHERSCAN_API_KEY=...
# NAME="Taxed Token"; SYMBOL="TT"; DECIMALS=18
# INITIAL_SUPPLY=1000000000000000000000000
# TOKEN_OWNER=0x...
# (optional) TAX_BPS=200; TAX_COLLECTOR=0x...
# (optional) TOKEN_FACTORY=0x...

# 3) Build
forge clean && forge build --build-info

# 4) Tests with gas
forge test -vvv --gas-report | tee reports/gas.txt
````

### Deploy (choose one)

#### Option A — Direct deploy with cast (robust)

```bash
# bytecode
BYTECODE=$(forge inspect contracts/TaxedERC20.sol:TaxedERC20 bytecode)

# deploy (Sepolia)
OWNER_ENV="${TOKEN_OWNER:-$INITIAL_OWNER}"
TX=$(cast send \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --create "$BYTECODE" \
  "constructor(string,string,uint8,uint256,address,uint16,address)" \
  "$NAME" "$SYMBOL" $DECIMALS $INITIAL_SUPPLY "$OWNER_ENV" ${TAX_BPS:-0} "${TAX_COLLECTOR:-$OWNER_ENV}")

NEW_TOKEN=$(echo "$TX" | awk '/^contractAddress/ {print $2}')
echo "NEW_TOKEN=$NEW_TOKEN"
```

#### Option B — Factory scripts

```bash
# deploy factory
forge script script/DeployTokenFactory.s.sol \
  --broadcast --rpc-url "$SEPOLIA_RPC_URL" -vvvv | tee reports/deploy-factory.txt

# create one token via factory (reads NAME/SYMBOL/DECIMALS/INITIAL_SUPPLY/TOKEN_OWNER)
forge script script/CreateOneToken.s.sol \
  --broadcast --rpc-url "$SEPOLIA_RPC_URL" -vvvv | tee reports/deploy-token.txt
```

### Verify on Etherscan (Exact Match)

```bash
# constructor args
ARGS=$(cast abi-encode \
  "constructor(string,string,uint8,uint256,address,uint16,address)" \
  "$NAME" "$SYMBOL" $DECIMALS $INITIAL_SUPPLY "$OWNER_ENV" ${TAX_BPS:-0} "${TAX_COLLECTOR:-$OWNER_ENV}")

forge verify-contract \
  --chain sepolia \
  --constructor-args "$ARGS" \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  "$NEW_TOKEN" \
  contracts/TaxedERC20.sol:TaxedERC20 \
  --watch
```

### Read checks

```bash
cast call "$NEW_TOKEN" "name()(string)"          --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "symbol()(string)"        --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "decimals()(uint8)"       --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "totalSupply()(uint256)"  --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "owner()(address)"        --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "taxBps()(uint16)"        --rpc-url "$SEPOLIA_RPC_URL"
cast call "$NEW_TOKEN" "taxCollector()(address)" --rpc-url "$SEPOLIA_RPC_URL"
```

> Optional — route tax to a router later：

```bash
# requires ROUTER in .env
cast send "$NEW_TOKEN" "setTax(uint16,address)" ${TAX_BPS:-200} "$ROUTER" \
  --rpc-url "$SEPOLIA_RPC_URL" --private-key "$PRIVATE_KEY"
```

---

## Evidence
Single source of truth → **[Evidence Index](./docs/evidence/README.md)**  
(CI gas report: GitHub Actions → latest run → Artifacts → `gas-ci.txt`)

---

## Project Layout

```
contracts/   # TokenFactory, TaxedERC20, SimpleERC20
script/      # Deploy scripts (factory, create-one-token)
test/        # Foundry tests
reports/     # Gas + deploy logs
docs/        # Evidence packs
```

> Security note: `.env` / `*.env` / `*.log` are ignored (see root & evm/.gitignore). Never commit private keys.