# Repos Collection

This repository contains several independent MVP projects showcasing my skills in Web3/Blockchain development.  
Each subfolder represents a standalone project, with details available in their respective README files.

- **audit_docker_mvp**: Smart contract automated auditing MVP  
- **defi-audit**: Security analysis tool for DeFi protocols  
- **nft-query**: NFT metadata and transaction query tool  
- **token_api**: Token data query and management API  

This collection is designed to demonstrate my comprehensive abilities in backend development, blockchain interaction, and security auditing.

**Demo**

A short demo video is provided to show:

1. Building and starting the services with Docker Compose  
2. Checking database and log status before the test  
3. Generating a JWT token  
4. Running the API call with POSTMAN 
5. Verifying fast response time (around 1 second, cached requests respond instantly)  
6. Confirming logs and database updates  

👉 Watch the demo video  
https://youtu.be/bJQyXpvDhhg

---

## EVM Launchkit (Foundry) — CI Status & Gas Evidence

![ci](https://github.com/lzh840723/launchkit/actions/workflows/ci.yml/badge.svg)

- **Workflow:** GitHub Actions runs `forge test -vvv` and publishes a gas report (`--gas-report`).
- **Artifacts:** Each run uploads `gas-ci.txt` as an artifact (downloadable).
- **How to view:** Go to **Actions → latest “ci” run → Artifacts → gas-ci** to download `gas-ci.txt`.

> Note: This repository is a collection of independent MVPs. The Foundry tests run **only** in the `evm/` subfolder via  
> `defaults.run.working-directory: evm`, so other projects remain unaffected.
