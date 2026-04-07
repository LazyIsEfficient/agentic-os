# Supported Networks and Configuration

## Supported Networks

| Network | Chain ID | RPC | Verification |
|---|---|---|---|
| Polygon Mainnet | 137 | Infura | PolygonScan |
| Polygon Amoy (Testnet) | 80002 | Infura | OKLink |
| Ronin Mainnet | 2020 | Custom RPC | Sourcify |
| Ronin Saigon (Testnet) | 2021 | Custom RPC | Sourcify |
| Base Mainnet | 8453 | Infura | BaseScan |
| Base Sepolia (Testnet) | 84532 | Infura | BaseScan |
| Abstract (ZKSync) | — | Custom RPC | Custom |

## Environment Variables

```
WEB3_INFURA_PROJECT_ID=
DEPLOYER_PRIV_KEY=
RONIN_RPC=
RONIN_SAIGON_RPC=
BASE_ETHERSCAN_API_KEY=
OKLINK_API_KEY=
POLYGONSCAN_API_KEY=
```

## Hardhat Configuration

```typescript
// hardhat.config.ts
const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.5',
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_KEY}`,
      accounts: [DEPLOYER_PRIV_KEY],
    },
    amoy: {
      url: `https://polygon-amoy.infura.io/v3/${INFURA_KEY}`,
      accounts: [DEPLOYER_PRIV_KEY],
    },
    ronin: { url: RONIN_RPC, accounts: [DEPLOYER_PRIV_KEY] },
    baseSepolia: {
      url: `https://base-sepolia.infura.io/v3/${INFURA_KEY}`,
      accounts: [DEPLOYER_PRIV_KEY],
    },
  },
  etherscan: {
    apiKey: { base: BASE_ETHERSCAN_API_KEY },
  },
  sourcify: {
    enabled: true,
    apiUrl: 'https://sourcify.roninchain.com/server/',
    browserUrl: 'https://sourcify-repo.roninchain.com',
  },
}
```

## Foundry Configuration

```toml
# foundry.toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@openzeppelin/=lib/openzeppelin-contracts/"]
solc_version = "0.8.2"

[etherscan]
amoy = { key = "${OKLINK_API_KEY}", url = "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/AMOY_TESTNET" }
polygon = { key = "${POLYGONSCAN_API_KEY}" }
```
