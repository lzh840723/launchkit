---

# Day 1 Deliverable (Baseline Setup)

> Mainline architecture for Day 1:
>
> * `TokenFactory (Ownable)` – creates ERC-20 tokens with a fixed tax (basis points) and a fee collector
> * `TaxedERC20` – ERC-20 with: fixed tax (bps) on transfers, owner whitelist (no-tax), pausability
>
> Toolchain: Solidity `0.8.24`, EVM `paris`, Foundry/Forge

---

## ✅ What’s Done on Day 1

* [x] **Workspace bootstrapped** under `evm/` using Foundry
* [x] **Dependencies installed** (`openzeppelin-contracts`, `forge-std`)
* [x] **Core contracts implemented**

  * `contracts/TaxedERC20.sol`

    * Transfer tax (`taxBps`, sent to `taxCollector`)
    * Owner-managed **whitelist** (no tax for whitelisted senders)
    * **Pause**/unpause via owner
  * `contracts/TokenFactory.sol` (Ownable)

    * `createToken(name, symbol, initialSupply, taxBps, taxCollector)`
      Mints 100% of initial supply to the **owner** passed into token constructor
* [x] **Basic tests** (sanity) ensuring:

  * Project compiles
  * Token can be created via factory
  * Simple transfers and supply invariants hold
* [x] **Foundry config** added (`foundry.toml`)
* [x] **Deployment script stub** for factory (`script/DeployFactory.s.sol`)

> Note: FeeRouter-based flow is **not** part of the Day 1 mainline. Any experimental Router files (if present) are parked for later milestones.

---

## 🗂 Directory Snapshot

```
evm/
├─ contracts/
│  ├─ TaxedERC20.sol
│  └─ TokenFactory.sol
├─ script/
│  └─ DeployFactory.s.sol
├─ test/
│  └─ (minimal sanity tests)
├─ foundry.toml
└─ lib/
   ├─ openzeppelin-contracts/
   └─ forge-std/
```

---

## ⚙️ Configuration (Foundry)

`evm/foundry.toml` (baseline used on Day 1; you may already have the merged Day 2 config):

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]

solc_version = "0.8.24"
evm_version  = "paris"
optimizer = true
optimizer_runs = 200

remappings = [
  "@openzeppelin/=lib/openzeppelin-contracts/",
  "forge-std/=lib/forge-std/src/"
]

# Optional quality-of-life settings (already used later):
# ffi = true
# fs_permissions = [{ access = "read", path = "./"}]

[fmt]
line_length = 100

[fuzz]
runs = 256

[etherscan]
# sepolia     = { key = "${ETHERSCAN_API_KEY}" }
# basesepolia = { key = "${BASESCAN_API_KEY}" }
```

---

## 🧾 Contract Notes

### `TaxedERC20.sol`

* **Constructor** (Day 1 mainline):

  ```
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply_,
    address owner_,
    uint16  taxBps_,
    address taxCollector_
  )
  ```
* **Key behavior**

  * On transfer: deduct `amount * taxBps / 10_000` to `taxCollector`, send the rest to the recipient
  * **Whitelist** (owner-managed): senders on the whitelist are not taxed
  * **Pausable**: owner can pause; transfers revert while paused
  * (Recommended) **Zero-address checks** for `owner_` and `taxCollector_` in constructor; `collector` in `setTax`

### `TokenFactory.sol` (Ownable)

* **Constructor**:

  ```
  constructor(address owner_) Ownable(owner_) {}
  ```
* **Create token**:

  ```
  function createToken(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply,
    uint16  taxBps,
    address taxCollector
  ) external onlyOwner returns (address)
  ```
* Emits `TokenCreated(address token, string name, string symbol)`.

---

## ▶️ How to Run (Day 1)

From the `evm/` directory:

```bash
# Install deps if not present
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit

# Build
forge build -vv

# Run sanity tests
forge test -vv
```

> If you later enable gas reports or coverage (introduced on Day 2), use:
>
> * `forge test --gas-report -vv`
> * `forge coverage`

---

## 📜 Minimal Sanity Tests (Examples)

You likely already evolved these on Day 2. For Day 1, keep them simple:

* **Factory creates a token and mints full supply to owner**
* **Basic transfer succeeds**
* **Pause makes transfer revert**
* **Whitelist sender transfer is not taxed (simple path)**

> Full functional and edge-case tests (tax distribution math, `transferFrom`, role/ownership transitions, etc.) are expanded on Day 2.

---

## 🚀 Deployment Stub (Testnet)

`script/DeployFactory.s.sol` (Day 1 stub; prints the deployed factory address):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../contracts/TokenFactory.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(pk);

        vm.startBroadcast(pk);
        TokenFactory factory = new TokenFactory(admin);
        vm.stopBroadcast();

        console2.log("TokenFactory:", address(factory));
    }
}
```

Run (example for Sepolia—requires `.env` with `PRIVATE_KEY` and `SEPOLIA_RPC_URL`):

```bash
forge script script/DeployFactory.s.sol \
  --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
```

---

## 📦 Day 1 Artifacts

* Code: `contracts/TaxedERC20.sol`, `contracts/TokenFactory.sol`
* Script: `script/DeployFactory.s.sol`
* Config: `foundry.toml`
* Tests: minimal sanity tests (later expanded in Day 2)

---

## 🗺️ Next (Day 2 Preview)

* Strengthen tests: tax math, whitelist, pause, `transferFrom`, factory permissions
* Add **gas report**, **coverage**, **Slither** static analysis
* Produce Day 2 docs and reports; prepare for testnet deployment & verification

---