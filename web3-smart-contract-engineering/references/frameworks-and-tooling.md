# Frameworks, Tooling, and Project Structure

## Frameworks and Tooling

- **Hardhat + Foundry hybrid**: Primary development environment
- **Thirdweb**: Deploy tooling and base contract extensions
- **Solidity versions**: 0.8.2 through 0.8.30 (version per workspace)
- **OpenZeppelin Contracts**: ^5.3.0 (with upgradeable variants ^5.4.0)
- **Ethers.js v6**: TypeScript contract interaction and testing
- **@matterlabs/hardhat-zksync**: ZKSync / Abstract chain deployment
- **Node.js 22+** with npm

## Key Dependencies

```
@nomicfoundation/hardhat-chai-matchers    # Test assertions
@nomicfoundation/hardhat-foundry          # Foundry integration
@nomicfoundation/hardhat-toolbox          # Compile, test, verify
@nomicfoundation/hardhat-verify           # Block explorer verification
@openzeppelin/contracts                   # Standard library
@openzeppelin/contracts-upgradeable       # Proxy-compatible contracts
@openzeppelin/hardhat-upgrades            # Upgrade tooling
merkletreejs                              # Merkle tree generation
hardhat-deploy                            # Deployment management
```

## Scripts

```bash
npm run compile          # Compile all contracts
npm run test             # Run Hardhat or Foundry tests
npm run lint             # Slither static analysis
npm run fork:polygon     # Fork Polygon mainnet locally
npm run deploy           # Thirdweb deploy (npx thirdweb@latest deploy)
```

## Project Structure

```
contracts-monorepo/
├── hhf_sol-0_8_2/                ← Hardhat+Foundry workspace (Solidity 0.8.2)
│   ├── src/                      ← Contract source
│   │   ├── MintableERC721.sol
│   │   ├── MintableERC1155.sol
│   │   ├── CollateralizedToken.sol
│   │   ├── SignatureMinter.sol
│   │   ├── MultiSoulboundRewarder.sol
│   │   ├── PaymentCode.sol
│   │   ├── BurningMinter.sol
│   │   └── StakingVault.sol
│   ├── test/                     ← TypeScript test files
│   ├── script/                   ← Deploy + verification scripts
│   ├── hardhat.config.ts
│   └── foundry.toml
├── hhf_sol-0_8_5/                ← Workspace (Solidity 0.8.5)
│   └── src/RoleBasedProxy.sol
├── thirdweb_sol-0_8_2/           ← Thirdweb workspace
│   └── contracts/
│       ├── ERC1155Badge.sol
│       └── Token.sol
└── deploys.ts                    ← Deployment records

platform-contracts/               ← Allocation + staking modules
├── contracts/
│   ├── AllocationModule.sol      ← Token launch + commitment system
│   ├── RewardMultiplier.sol
│   └── StakingVault.sol
├── deploy/                       ← hardhat-deploy scripts
└── test/

redeem-app/apps/smart-contract/   ← Reward payout system
├── contracts/
│   ├── RewardPayout.sol          ← Signature-gated claims
│   ├── RewardPayoutFactory.sol   ← Multi-vault factory
│   └── TestToken.sol
└── test/
```
