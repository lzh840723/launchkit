# Repos Collection

This repository contains several independent MVP projects showcasing my skills in Web3/Blockchain development.  
Each subfolder represents a standalone project, with details available in their respective README files.

- **audit_docker_mvp**: Smart contract automated auditing MVP  
- **defi-audit**: Security analysis tool for DeFi protocols  
- **nft-query**: NFT metadata and transaction query tool  
- **token_api**: Token data query and management API  
- **evm**: EVM Launchkit (Foundry) — token factory, tax-enabled ERC20, tests, CI & evidence

This collection demonstrates comprehensive abilities in backend development, blockchain interaction, security auditing, and DevEx.

---

## Demo Video

1) Build & start with Docker Compose  
2) Check DB & logs  
3) Generate JWT  
4) Call API with POSTMAN  
5) Verify response time (~1s; cached requests instant)  
6) Confirm logs & DB updates

👉 Watch: https://youtu.be/bJQyXpvDhhg

---

## EVM Launchkit (Foundry) — CI Status & Gas Evidence

![ci](https://github.com/lzh840723/launchkit/actions/workflows/ci.yml/badge.svg)

- **Workflow:** GitHub Actions runs `forge test -vvv` and publishes a gas report (`--gas-report`).
- **Artifacts:** Each run uploads `gas-ci.txt` as an artifact (downloadable).
- **Where:** Actions → latest “ci” run → Artifacts → `gas-ci`.

> Note: The workflow runs **only** in the `evm/` subfolder via `defaults.run.working-directory: evm`.

---

## EVM — Evidence Packs

- Day4: [Evidence (CI)](./evm/docs/evidence/day4/evidence-ci.md)  
- Day5: [Evidence Pack #1](./evm/docs/evidence/day5/pack.md)  
- **Day6**: [Evidence Pack — TaxedERC20 (OZ v5)](./evm/docs/evidence/day6/pack.md)

---

## Fixed-price Offers (Productized)

- **#1 – Token Factory (simple ERC20)**
  - Delivery: factory contract, scripts, tests, gas report, usage notes.

- **#2 – TaxedERC20 (OZ v5): tax / whitelist / blacklist / pause**
  - Delivery: ERC20 with tax via `_update` hook, owner controls, tests, gas report, evidence pack.
  - Evidence: see Day6 pack above.

For service details or custom extensions, open an issue or contact me.
