# Deployment

## Deploy Scripts

```bash
# Foundry (Polygon)
./script/polygon_deploy.sh matic src/SignatureMinter.sol:SignatureMinter \
    --constructor-args "0x4800..." "0x2111..." "0x05A6..."

# Hardhat
npx hardhat run script/deploy.ts --network polygon

# Thirdweb
npx thirdweb@latest deploy -k $THIRDWEB_SECRET

# Abstract (ZKSync)
npm run deploy:abstract-testnet
npm run deploy:abstract-mainnet
```

## Verification

```bash
# Hardhat verify
npx hardhat verify 0xContractAddress --network polygon

# Foundry verify with constructor args
./script/polygon_verify.sh matic 0xAddress src/Contract.sol:Contract \
    --constructor-args $(cast abi-encode "constructor(address,uint256)" "0x..." "100")
```

Ronin uses Sourcify (configured in `hardhat.config.ts`).

## Deployment Tracking

Record every deployment in `deploys.ts`:

```typescript
{
  name: 'SignatureMinter - Polygon',
  date: '2025-01-15',
  network: 'polygon',
  contract: 'SignatureMinter',
  address: '0x766b929D...',
  args: '0x4800... 0x2111... 0x05A6...',
  verify_cmd: 'npx hardhat verify 0x766b929D... --network polygon',
}
```
