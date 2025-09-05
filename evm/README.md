# EVM Launchkit (Foundry)

A compact Launchkit for shipping ERC20 tokens and a factory, built with **Foundry** and **OpenZeppelin v5**.  
Includes CI, tests, gas reports, and ready-to-use scripts.

---

## What’s inside

- **TokenFactory** — deploy ERC20 tokens with guardrails & event logs
- **TaxedERC20 (Day6)** — ERC20 with:
  - **Transfer tax** (basis points) sent to a **tax collector**
  - **Whitelist** (tax-exempt) and **Blacklist** (blocked)
  - **Pause/Unpause** using OZ v5’s unified `_update` hook with `EnforcedPause()`
  - Custom **decimals**
- **Tests** — Foundry unit & integration tests, `--gas-report`
- **Scripts** — deploy factory and create a token via factory
- **Evidence** — on-chain addresses, logs, gas, and test artifacts

---

## Quickstart

```bash
# 1) Install dependencies
forge install

# 2) Set up environment (edit .env)
cp .env.example .env   # if exists; otherwise fill manually
# Required vars:
#   PRIVATE_KEY=0x...
#   OWNER=0x...
#   SEPOLIA_RPC_URL=...
#   ETHERSCAN_API_KEY=...       # for optional verification
#   NAME="Taxed Token"
#   SYMBOL="TT"
#   DECIMALS=18
#   INITIAL_SUPPLY=1000000000000000000000000
#   TOKEN_OWNER=0x...
#   TOKEN_FACTORY=0x...         # your deployed factory

# 3) Run tests (with gas)
forge test -vvv --gas-report | tee reports/gas-day6.txt

```
Deploy & Use
# Deploy the TokenFactory to Sepolia
forge script script/DeployTokenFactory.s.sol \
  --broadcast --rpc-url $SEPOLIA_RPC_URL -vvvv | tee reports/deploy-factory.txt

# Create one token via factory (reads env: NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY, TOKEN_OWNER)
forge script script/CreateOneToken.s.sol \
  --broadcast --rpc-url $SEPOLIA_RPC_URL -vvvv | tee reports/deploy-day6.txt
Basic checks
cast call $NEW_TOKEN "name()(string)"         --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "symbol()(string)"       --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "decimals()(uint8)"      --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "totalSupply()(uint256)" --rpc-url $SEPOLIA_RPC_URL
cast call $NEW_TOKEN "owner()(address)"       --rpc-url $SEPOLIA_RPC_URL

On-chain (Sepolia)
* Factory: 0x09139374cb2aBFb3f989D1FC12F83905f01f1B5c
* Token: 0x88b5DC0B57605A552716a1591b39965085cb8Eb1
* Owner: 0x0297C0Df7FdB329676711B4958FEAA33aE9633aB

Optional: Etherscan Verification
# Factory
forge verify-contract \
  0x09139374cb2aBFb3f989D1FC12F83905f01f1B5c \
  contracts/TokenFactory.sol:TokenFactory \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia

# Token (constructor args must match your factory's new TaxedERC20(...) call)
# Prepare constructor-args with cast (example only; adjust if you changed tax bps / collector)
# cast abi-encode "constructor(string,string,uint8,uint256,address,uint16,address)" \
#  "Taxed Token" "TT" 18 1000000000000000000000000 0x0297C0Df7FdB329676711B4958FEAA33aE9633aB 200 0x0297C0Df7FdB329676711B4958FEAA33aE9633aB

# Then:
# forge verify-contract \
#   0x88b5DC0B57605A552716a1591b39965085cb8Eb1 \
#   contracts/TaxedERC20.sol:TaxedERC20 \
#   --etherscan-api-key $ETHERSCAN_API_KEY \
#   --chain sepolia \
#   --constructor-args $(< encoded_args.txt)

Evidence
* CI gas report: Actions → latest run → Summary (embedded table), Artifacts → gas-ci.txt
* Day6 Evidence Pack: docs/evidence/day6/pack.md
* Logs:
    * reports/deploy-factory.txt
    * reports/deploy-day6.txt
    * reports/gas-day6.txt

Project Layout
contracts/   # TokenFactory, TaxedERC20, SimpleERC20
script/      # Deploy scripts (factory, create-one-token)
test/        # Foundry tests (factory + TaxedERC20)
reports/     # Gas + deploy logs
docs/        # Evidence packs

---

## Day8 — VestingVault + Minimal Frontend
- Evidence: `evm/docs/evidence/day8/verify-links.md`
- Addresses: `evm/docs/evidence/day8/addresses.json`
- Transactions: `evm/docs/evidence/day8/txs.md`
- Gas: `evm/docs/evidence/day8/gas-day8.txt`
- Frontend: `vesting-ui/` (Connect + Releasable + Claim)

---

## Day9 — Slither Hardening
- Evidence: `evm/docs/evidence/day9/summary.md`
- Before (JSON/MD): `evm/docs/evidence/day9/slither-before.json`, `evm/docs/evidence/day9/slither-before.md`
- After (JSON/MD): `evm/docs/evidence/day9/slither-after.json`, `evm/docs/evidence/day9/slither-after.md`
- Diff: `evm/docs/evidence/day9/slither-diff.md`
- Logs (full): `evm/reports/slither-after-full.md`