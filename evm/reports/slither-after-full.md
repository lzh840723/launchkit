'forge config --json' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 --version' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 @openzeppelin/=lib/openzeppelin-contracts/ forge-std/=lib/forge-std/src/ ds-test/=lib/openzeppelin-contracts/lib/forge-std/lib/ds-test/src/ erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/ halmos-cheatcodes/=lib/openzeppelin-contracts/lib/halmos-cheatcodes/src/ openzeppelin-contracts/=lib/openzeppelin-contracts/ contracts/FeeRouter.sol --combined-json abi,ast,bin,bin-runtime,srcmap,srcmap-runtime,userdoc,devdoc,hashes --optimize --optimize-runs 200 --evm-version paris --allow-paths .,/Users/lzh/dev/launchkit/evm/contracts' running
'forge config --json' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 --version' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 @openzeppelin/=lib/openzeppelin-contracts/ forge-std/=lib/forge-std/src/ ds-test/=lib/openzeppelin-contracts/lib/forge-std/lib/ds-test/src/ erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/ halmos-cheatcodes/=lib/openzeppelin-contracts/lib/halmos-cheatcodes/src/ openzeppelin-contracts/=lib/openzeppelin-contracts/ contracts/VestingVault.sol --combined-json abi,ast,bin,bin-runtime,srcmap,srcmap-runtime,userdoc,devdoc,hashes --optimize --optimize-runs 200 --evm-version paris --allow-paths .,/Users/lzh/dev/launchkit/evm/contracts' running
'forge config --json' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 --version' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 @openzeppelin/=lib/openzeppelin-contracts/ forge-std/=lib/forge-std/src/ ds-test/=lib/openzeppelin-contracts/lib/forge-std/lib/ds-test/src/ erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/ halmos-cheatcodes/=lib/openzeppelin-contracts/lib/halmos-cheatcodes/src/ openzeppelin-contracts/=lib/openzeppelin-contracts/ contracts/TokenFactory.sol --combined-json abi,ast,bin,bin-runtime,srcmap,srcmap-runtime,userdoc,devdoc,hashes --optimize --optimize-runs 200 --evm-version paris --allow-paths .,/Users/lzh/dev/launchkit/evm/contracts' running
'forge config --json' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 --version' running
'/Users/lzh/.solc-select/artifacts/solc-0.8.24/solc-0.8.24 @openzeppelin/=lib/openzeppelin-contracts/ forge-std/=lib/forge-std/src/ ds-test/=lib/openzeppelin-contracts/lib/forge-std/lib/ds-test/src/ erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/ halmos-cheatcodes/=lib/openzeppelin-contracts/lib/halmos-cheatcodes/src/ openzeppelin-contracts/=lib/openzeppelin-contracts/ contracts/TaxedERC20.sol --combined-json abi,ast,bin,bin-runtime,srcmap,srcmap-runtime,userdoc,devdoc,hashes --optimize --optimize-runs 200 --evm-version paris --allow-paths .,/Users/lzh/dev/launchkit/evm/contracts' running
INFO:Printers:
Compiled with solc
Total number of contracts in source files: 7
Source lines of code (SLOC) in source files: 223
Number of  assembly lines: 0
Number of optimization issues: 0
Number of informational issues: 0
Number of low issues: 0
Number of medium issues: 0
Number of high issues: 0

ERCs: ERC20

+--------------+-------------+-------+--------------------+--------------+--------------------+
| Name         | # functions | ERCS  | ERC20 info         | Complex code | Features           |
+--------------+-------------+-------+--------------------+--------------+--------------------+
| FeeRouter    | 13          |       |                    | No           | Send ETH           |
|              |             |       |                    |              | Tokens interaction |
| IERC20       | 6           | ERC20 | No Minting         | No           |                    |
|              |             |       | Approve Race Cond. |              |                    |
|              |             |       |                    |              |                    |
| IERC20Permit | 3           |       |                    | No           |                    |
| SafeERC20    | 7           |       |                    | No           | Send ETH           |
|              |             |       |                    |              | Tokens interaction |
| Address      | 8           |       |                    | No           | Send ETH           |
|              |             |       |                    |              | Delegatecall       |
|              |             |       |                    |              | Assembly           |
+--------------+-------------+-------+--------------------+--------------+--------------------+
INFO:Printers:
Compiled with solc
Total number of contracts in source files: 8
Source lines of code (SLOC) in source files: 272
Number of  assembly lines: 0
Number of optimization issues: 0
Number of informational issues: 0
Number of low issues: 3
Number of medium issues: 0
Number of high issues: 0

ERCs: ERC20

+--------------+-------------+-------+--------------------+--------------+--------------------+
| Name         | # functions | ERCS  | ERC20 info         | Complex code | Features           |
+--------------+-------------+-------+--------------------+--------------+--------------------+
| VestingVault | 18          |       |                    | No           |                    |
| IERC20       | 6           | ERC20 | No Minting         | No           |                    |
|              |             |       | Approve Race Cond. |              |                    |
|              |             |       |                    |              |                    |
| IERC20Permit | 3           |       |                    | No           |                    |
| SafeERC20    | 7           |       |                    | No           | Send ETH           |
|              |             |       |                    |              | Tokens interaction |
| Address      | 8           |       |                    | No           | Send ETH           |
|              |             |       |                    |              | Delegatecall       |
|              |             |       |                    |              | Assembly           |
+--------------+-------------+-------+--------------------+--------------+--------------------+
INFO:Printers:
Compiled with solc
Total number of contracts in source files: 25
Source lines of code (SLOC) in source files: 1194
Number of  assembly lines: 0
Number of optimization issues: 1
Number of informational issues: 0
Number of low issues: 0
Number of medium issues: 0
Number of high issues: 0

ERCs: ERC2612, ERC20

+------------------+-------------+---------------+--------------------+--------------+--------------------+
| Name             | # functions | ERCS          | ERC20 info         | Complex code | Features           |
+------------------+-------------+---------------+--------------------+--------------+--------------------+
| TaxedERC20       | 68          | ERC20,ERC2612 | Pausable           | No           | Send ETH           |
|                  |             |               | No Minting         |              | Ecrecover          |
|                  |             |               | Approve Race Cond. |              |                    |
|                  |             |               |                    |              |                    |
| TokenFactory     | 12          |               |                    | No           |                    |
| IERC721Errors    | 0           |               |                    | No           |                    |
| IERC1155Errors   | 0           |               |                    | No           |                    |
| SafeERC20        | 7           |               |                    | No           | Send ETH           |
|                  |             |               |                    |              | Tokens interaction |
| Address          | 8           |               |                    | No           | Send ETH           |
|                  |             |               |                    |              | Delegatecall       |
|                  |             |               |                    |              | Assembly           |
| ShortStrings     | 7           |               |                    | No           | Assembly           |
| StorageSlot      | 8           |               |                    | No           | Assembly           |
| Strings          | 7           |               |                    | No           | Assembly           |
| ECDSA            | 7           |               |                    | No           | Ecrecover          |
|                  |             |               |                    |              | Assembly           |
| MessageHashUtils | 4           |               |                    | No           | Assembly           |
| Math             | 20          |               |                    | Yes          | Assembly           |
| SignedMath       | 4           |               |                    | No           |                    |
+------------------+-------------+---------------+--------------------+--------------+--------------------+
INFO:Printers:
Compiled with solc
Total number of contracts in source files: 24
Source lines of code (SLOC) in source files: 1140
Number of  assembly lines: 0
Number of optimization issues: 1
Number of informational issues: 0
Number of low issues: 0
Number of medium issues: 0
Number of high issues: 0

ERCs: ERC2612, ERC20

+------------------+-------------+---------------+--------------------+--------------+--------------------+
| Name             | # functions | ERCS          | ERC20 info         | Complex code | Features           |
+------------------+-------------+---------------+--------------------+--------------+--------------------+
| TaxedERC20       | 68          | ERC20,ERC2612 | Pausable           | No           | Send ETH           |
|                  |             |               | No Minting         |              | Ecrecover          |
|                  |             |               | Approve Race Cond. |              |                    |
|                  |             |               |                    |              |                    |
| IERC721Errors    | 0           |               |                    | No           |                    |
| IERC1155Errors   | 0           |               |                    | No           |                    |
| SafeERC20        | 7           |               |                    | No           | Send ETH           |
|                  |             |               |                    |              | Tokens interaction |
| Address          | 8           |               |                    | No           | Send ETH           |
|                  |             |               |                    |              | Delegatecall       |
|                  |             |               |                    |              | Assembly           |
| ShortStrings     | 7           |               |                    | No           | Assembly           |
| StorageSlot      | 8           |               |                    | No           | Assembly           |
| Strings          | 7           |               |                    | No           | Assembly           |
| ECDSA            | 7           |               |                    | No           | Ecrecover          |
|                  |             |               |                    |              | Assembly           |
| MessageHashUtils | 4           |               |                    | No           | Assembly           |
| Math             | 20          |               |                    | Yes          | Assembly           |
| SignedMath       | 4           |               |                    | No           |                    |
+------------------+-------------+---------------+--------------------+--------------+--------------------+
INFO:Slither:contracts/ analyzed (64 contracts)
