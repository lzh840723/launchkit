## VestingVault (Sepolia)
- Address: 0xEBBfC15a41808dC2d3f7feFB16Db2075a195A14E
- Deployer: '"$DEPLOYER"'
- Token: '"$TOKEN"'
- Beneficiary: '"$VESTING_BENEFICIARY"'
- Start/Duration/Cliff: '"$VESTING_START"' / '"$VESTING_DURATION"' / '"$VESTING_CLIFF"'
- Verify: `forge verify-contract --chain sepolia --watch --constructor-args $ARGS 0xEBBf... contracts/VestingVault.sol:VestingVault`
