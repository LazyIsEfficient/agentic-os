---
name: web3-smart-contract-engineering
description: This skill provides Web3 and Solidity smart contract engineering rules covering Hardhat, Foundry, Thirdweb, OpenZeppelin, signature verification, merkle trees, ERC4626 vaults, token allocation systems, and multi-chain deployment. Automatically loaded when writing Solidity, deploying contracts, reviewing smart contracts, or when "smart contract", "Solidity", "Web3", "EVM", "Hardhat", "Foundry", "ERC20", "ERC721", "ERC1155", "staking", "merkle", or "on-chain" are mentioned.
---

# Web3 / Smart Contract Engineering Rules (Solidity + TypeScript)

## Frameworks and Tooling

- **Hardhat + Foundry hybrid**: Primary development environment
- **Thirdweb**: Deploy tooling and base contract extensions
- **Solidity versions**: 0.8.2 through 0.8.30 (version per workspace)
- **OpenZeppelin Contracts**: ^5.3.0 (with upgradeable variants ^5.4.0)
- **Ethers.js v6**: TypeScript contract interaction and testing
- **@matterlabs/hardhat-zksync**: ZKSync / Abstract chain deployment
- **Node.js 22+** with npm

### Key Dependencies

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

### Scripts

```bash
npm run compile          # Compile all contracts
npm run test             # Run Hardhat or Foundry tests
npm run lint             # Slither static analysis
npm run fork:polygon     # Fork Polygon mainnet locally
npm run deploy           # Thirdweb deploy (npx thirdweb@latest deploy)
```

## Project Structure

```
ygg-contracts/
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

ygg-play-platform-contracts/      ← Allocation + staking modules
├── contracts/
│   ├── AllocationModule.sol      ← Token launch + commitment system
│   ├── RewardMultiplier.sol
│   └── StakingVault.sol
├── deploy/                       ← hardhat-deploy scripts
└── test/

ygg-redeem/apps/smart-contract/   ← Reward payout system
├── contracts/
│   ├── RewardPayout.sol          ← Signature-gated claims
│   ├── RewardPayoutFactory.sol   ← Multi-vault factory
│   └── TestToken.sol
└── test/
```

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

### Environment Variables

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

## Core Contract Patterns

### Token Contracts

**MintableERC721** — Ownable, pausable, single-minter with batch support:

```solidity
contract MintableERC721 is ERC721URIStorage, Ownable, ERC721Pausable {
    address public minter;
    uint256 private currentTokenId;
    mapping(uint256 => bool) public mintingStopped;

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, string memory uri) public onlyMinter returns (uint256) {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        _setTokenURI(currentTokenId, uri);
        return currentTokenId;
    }

    function mintBatch(address to, uint256 count) public onlyMinter { ... }
    function stopMinting(uint256[] calldata ids) external onlyOwner { ... }
}
```

**MintableERC1155 (Soulbound)** — Non-transferable, all transfer methods revert:

```solidity
contract MintableERC1155 is ERC1155Pausable, Ownable {
    mapping(uint256 => bool) public mintingStopped;

    modifier onlyUnstopped(uint256 id) {
        require(!mintingStopped[id], "Minting stopped for this id");
        _;
    }

    // All transfers blocked — soulbound tokens
    function safeTransferFrom(...) public pure override { revert("Non-transferable"); }
    function safeBatchTransferFrom(...) public pure override { revert("Non-transferable"); }
}
```

**CollateralizedToken** — ERC20 backed by multiple collateral tokens with nested redemption:

```solidity
struct CollateralConfig {
    bool enabled;
    bool isNestedCollateralToken;
    uint256 index;
    address token;
}

function redeem(uint256 amount, bool unwrap_nested, address beneficiary) public {
    uint256 share;
    for (uint i = 0; i < collateralTokens.length; i++) {
        CollateralConfig memory config = collateralConfigs[collateralTokens[i]];
        if (!config.enabled) continue;

        share = IERC20(config.token).balanceOf(address(this)) * amount / totalSupply();

        if (config.isNestedCollateralToken && unwrap_nested) {
            CollateralizedToken(config.token).redeem(share, unwrap_nested, beneficiary);
        } else {
            IERC20(config.token).transfer(beneficiary, share);
        }
    }
    _burn(msg.sender, amount);
}
```

### Signature Verification Pattern

Used across `SignatureMinter`, `PaymentCode`, and `RewardPayout`:

```solidity
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Build hash from claim parameters
bytes32 hash = keccak256(abi.encodePacked(
    block.chainid,       // Prevent cross-chain replay
    address(this),       // Prevent cross-contract replay
    msg.sender,
    claimId,
    amount,
    asset,
    deadline
));

// Verify EIP-191 signed message
bytes32 ethSignedHash = hash.toEthSignedMessageHash();
address recovered = ethSignedHash.recover(signature);
require(recovered == authorizedSigner, "Invalid signature");

// Prevent replay
require(!usedHashes[ethSignedHash], "Already claimed");
usedHashes[ethSignedHash] = true;
```

**Rules**:
- Always include `block.chainid` and `address(this)` in signed data
- Always track used hashes to prevent replay
- Include a deadline or expiry for time-bounded claims
- Use `ECDSA.recover` from OpenZeppelin — never roll your own

### TypeScript Signature Generation (Tests/Backend)

```typescript
async function generateSignature(
  amount: bigint,
  paymentCode: string,
  to: string,
  tokenAddress: string,
  tokenId: bigint,
  tokenType: number,
  velocityControlId: bigint,
  privateKey: string,
) {
  const paymentCodeHash = ethers.keccak256(ethers.toUtf8Bytes(paymentCode))

  const firstHash = ethers.solidityPackedKeccak256(
    ['uint256', 'bytes32', 'address', 'address', 'uint256', 'uint8', 'uint256'],
    [amount, paymentCodeHash, to, tokenAddress, tokenId, tokenType, velocityControlId],
  )

  const prefix = '\x19Ethereum Signed Message:\n32'
  const message = ethers.solidityPackedKeccak256(
    ['string', 'bytes32'],
    [prefix, firstHash],
  )

  const signingKey = new ethers.SigningKey(privateKey)
  return signingKey.sign(message)
}
```

### Merkle Proof Verification

Used in `StakingVault` (deposits) and `AllocationModule` (claims):

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Single-param leaf (deposit cap)
bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAllowed));
require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

// Multi-param leaf (claim)
bytes32 leaf = keccak256(abi.encode(token, index, account, tokenAmount, yggRefund));
require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
```

**TypeScript Merkle Tree Generation** (`merkletreejs`):

```typescript
import { MerkleTree } from 'merkletreejs'
import { keccak256, solidityPacked } from 'ethers'

const leaves = allocations.map((a) =>
  keccak256(solidityPacked(
    ['address', 'uint256', 'uint256', 'uint256'],
    [a.address, a.index, a.tokenAmount, a.yggRefund],
  ))
)

const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })
const root = tree.getHexRoot()
const proof = tree.getHexProof(leaves[index])
```

### Velocity Control (Rate Limiting)

`PaymentCode.sol` implements configurable rate limiting:

```solidity
struct VelocityControl {
    uint256 maxPerClaim;        // Per-transaction limit
    uint256 maxTotalClaimed;    // Lifetime limit
    uint256 totalClaimed;       // Running total
    uint256 lastClaimedAt;      // Last claim timestamp
    uint256 expiry;             // Hard deadline
    uint256 intervalLimit;      // Per-interval ceiling
    uint256 interval;           // Time period (seconds)
    uint256 intervalStart;      // Current period start
    bool enabled;
}
```

Interval rolling window logic:

```solidity
function getIntervalAllowedAmount(VelocityControl storage vc) internal view returns (uint256) {
    if (block.timestamp >= vc.intervalStart + vc.interval) {
        return vc.intervalLimit; // New period, full allowance
    }
    return vc.intervalLimit - vc.intervalClaimed; // Remaining in current period
}
```

### ERC4626 Staking Vault

SNX-style reward distribution via tokenized vault shares:

```solidity
contract StakingVault is ERC4626, ReentrancyGuard {
    struct DepositConfig {
        address token;
        uint256 startTs;
        bytes32 merkleRoot;
        bool preventAfterStart;  // No deposits after reward start
        bool fullLock;           // Locked until reward period ends
    }

    // SNX reward math
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) return rewardPerTokenStored;
        return rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply();
    }

    function earned(address account) public view returns (uint256) {
        return (balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18
            + rewards[account];
    }

    // Merkle-gated deposits with per-wallet caps
    function merkleDeposit(uint256 amount, uint256 maxAllowed, bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAllowed));
        require(MerkleProof.verify(proof, depositConfig.merkleRoot, leaf), "Invalid proof");
        require(deposited[msg.sender] + amount <= maxAllowed, "Exceeds cap");
        deposit(amount, msg.sender);
    }
}
```

### Allocation Module (Token Launch System)

State machine for token commitments, claims, and refunds:

```solidity
enum AllocState { NULL, COMMITTING, CLAIMABLE, REFUNDED }

struct AllocData {
    AllocState state;
    uint160 sqrtPriceX96;        // Uniswap V3 initial price
    uint24 uniV3Fee;             // Pool fee tier (500, 3000, 10000)
    uint256 targetYGG;
    uint256 perWalletCap;
    uint256 totalCommitted;
    uint256 minCommit;           // Minimum to succeed
    uint256 commitStartTime;
    uint256 commitEndTime;
    uint256 adminDeadline;       // 7 days post-commit — auto-refund if missed
    bytes32 merkleRoot;
    uint256 claimedSoFar;
    uint256 refundedSoFar;
}
```

Lifecycle:
1. Owner creates allocation with parameters
2. Users commit YGG during `commitStartTime..commitEndTime` (signed quota)
3. Admin sets merkle root → state transitions to `CLAIMABLE`
4. Users claim new tokens + YGG refunds via merkle proof
5. If admin misses deadline → auto-transitions to `REFUNDED`

Advanced features:
- **CREATE2 deterministic token deployment**: Pre-calculate token address
- **Uniswap V3 LP creation**: Full-range position minted on state transition
- **EIP-712 style signed quotas**: Off-chain allocation verification

### Role-Based Proxy (Multi-Sig Governance)

Per-role, per-method approval thresholds:

```solidity
contract RoleBasedProxy is AccessControl, Pausable, ReentrancyGuard {
    struct Proposal {
        uint256 id;
        address target;
        bytes data;
        bytes4 method;            // Function selector
        bytes32 requiredRole;
        uint256 approvals;
        bool executed;
    }

    mapping(bytes32 => mapping(bytes4 => mapping(address => bool))) public allowedMethods;
    mapping(bytes32 => mapping(bytes4 => uint256)) public approvalThresholds;

    function submitProposal(bytes32 role, address target, bytes calldata data) external {
        bytes4 method = bytes4(data[:4]);
        require(allowedMethods[role][method][target], "Method not allowed");
        // Auto-counts proposer's approval
    }

    function executeProposal(uint256 proposalId) external {
        require(proposal.approvals >= threshold, "Insufficient approvals");
        (bool success,) = proposal.target.call(proposal.data);
        require(success, "Execution failed");
    }
}
```

### Factory Pattern (RewardPayout)

```solidity
contract RewardPayoutFactory is AccessControl {
    mapping(address => bool) public isPayoutContract;
    address[] public allPayoutContracts;

    function createPayoutContract(address signer, address admin) external onlyRole(ADMIN_ROLE)
        returns (address)
    {
        RewardPayout payout = new RewardPayout(signer, admin);
        isPayoutContract[address(payout)] = true;
        allPayoutContracts.push(address(payout));
        return address(payout);
    }

    // Batch admin operations across all vaults
    function batchWhitelistAsset(address[] calldata contracts, address asset) external { ... }
    function batchPauseContracts(address[] calldata contracts) external { ... }
    function batchAdminWithdraw(address[] calldata contracts, address[] calldata assets) external { ... }
}
```

## Testing Patterns

### Hardhat + Chai + Ethers.js v6

```typescript
import { ethers } from 'hardhat'
import { expect } from 'chai'
import * as helpers from '@nomicfoundation/hardhat-network-helpers'

describe('RoleBasedProxy', function () {
  let proxy: RoleBasedProxy
  let target: MockContract
  let owner: SignerWithAddress
  let addr1: SignerWithAddress
  let addr2: SignerWithAddress

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners()

    const ProxyFactory = await ethers.getContractFactory('RoleBasedProxy')
    proxy = await ProxyFactory.deploy()
    await proxy.waitForDeployment()

    const TargetFactory = await ethers.getContractFactory('MockContract')
    target = await TargetFactory.deploy()
    await target.waitForDeployment()
  })

  it('should submit and execute a proposal', async function () {
    const selector = target.interface.getFunction('doSomething').selector

    // Setup permissions
    await proxy.setAllowedMethod(ROLE, selector, await target.getAddress(), true)
    await proxy.setApprovalThreshold(ROLE, selector, 1)

    // Submit proposal
    const callData = target.interface.encodeFunctionData('doSomething', [42])
    const tx = await proxy.submitProposal(ROLE, await target.getAddress(), callData)

    // Execute
    await proxy.executeProposal(1)

    // Verify
    expect(await target.value()).to.equal(42)
  })

  it('should emit event on execution', async function () {
    await expect(proxy.executeProposal(1))
      .to.emit(proxy, 'ProposalExecuted')
      .withArgs(1, owner.address)
  })
})
```

### Time Manipulation

```typescript
import * as helpers from '@nomicfoundation/hardhat-network-helpers'

// Advance time for expiry/deadline testing
const currentTime = await helpers.time.latest()
await helpers.time.increase(3600) // 1 hour
await helpers.time.increaseTo(currentTime + 86400) // specific timestamp

// Mine blocks
await helpers.mine(10)
```

### Signature Testing

```typescript
it('should verify claim signature', async function () {
  const sig = await generateSignature(
    ethers.parseEther('100'),
    'payment-code-001',
    addr1.address,
    tokenAddress,
    0n,
    0, // ERC20
    1n,
    SIGNER_PRIVATE_KEY,
  )

  await expect(
    paymentCode.connect(addr1).claim(
      ethers.parseEther('100'),
      ethers.keccak256(ethers.toUtf8Bytes('payment-code-001')),
      addr1.address,
      tokenAddress,
      0,
      0,
      1,
      ethers.concat([sig.r, sig.s, ethers.toBeHex(sig.v)]),
    ),
  ).to.not.be.reverted
})
```

### Merkle Proof Testing

```typescript
it('should verify merkle deposit', async function () {
  const leaves = allowlist.map((entry) =>
    ethers.keccak256(
      ethers.solidityPacked(['address', 'uint256'], [entry.address, entry.maxAllowed]),
    ),
  )
  const tree = new MerkleTree(leaves, ethers.keccak256, { sortPairs: true })
  const proof = tree.getHexProof(leaves[0])

  await vault.connect(user).merkleDeposit(
    ethers.parseEther('50'),
    ethers.parseEther('100'),
    proof,
  )

  expect(await vault.deposited(user.address)).to.equal(ethers.parseEther('50'))
})
```

## Deployment

### Deploy Scripts

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

### Verification

```bash
# Hardhat verify
npx hardhat verify 0xContractAddress --network polygon

# Foundry verify with constructor args
./script/polygon_verify.sh matic 0xAddress src/Contract.sol:Contract \
    --constructor-args $(cast abi-encode "constructor(address,uint256)" "0x..." "100")
```

Ronin uses Sourcify (configured in `hardhat.config.ts`).

### Deployment Tracking

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

## Security Rules

### Required Patterns

1. **ReentrancyGuard** — on all functions that transfer tokens or ETH
2. **Pausable** — on all user-facing operations; owner can emergency-pause
3. **AccessControl** — for multi-role permission systems (prefer over `Ownable` for complex contracts)
4. **SafeERC20** — for all `transfer` / `transferFrom` / `approve` calls
5. **ECDSA signature verification** — always via OpenZeppelin, never custom
6. **Replay protection** — `usedHashes` mapping on every signature-gated function
7. **Cross-chain replay prevention** — include `block.chainid` and `address(this)` in signed data
8. **Merkle proof verification** — via `MerkleProof.verify` from OpenZeppelin

### Rate Limiting

Use velocity controls for any claim/payout function:
- Per-transaction max (`maxPerClaim`)
- Lifetime max (`maxTotalClaimed`)
- Rolling time-interval limits (`intervalLimit` / `interval`)
- Per-token daily limits
- Hard expiry deadlines

### Access Control

- Single-owner contracts: `Ownable` with `onlyOwner`
- Multi-role contracts: `AccessControl` with granular roles
- Multi-sig operations: `RoleBasedProxy` with per-method approval thresholds
- Minter pattern: Dedicated `minter` address with `onlyMinter` modifier

### Token Safety

- Use `forceApprove()` before Uniswap or DEX interactions (handles non-standard ERC20s)
- Clear approvals after operations
- Check return values on all external calls
- Use `_safeMint` for ERC721 (checks receiver)

## Gas Optimization Patterns

1. **Storage packing** — group related fields in structs to share slots
2. **Batch operations** — `mintBatch()`, `bulkClaim()`, `batchSet*()` to amortize base gas
3. **Cache storage reads** — `AllocData memory a = allocations[token]` before loops
4. **`unchecked` blocks** — for math proven not to overflow (tick calculations, counters)
5. **Immutable variables** — use `immutable` for values set once in constructor
6. **Short-circuit reverts** — check cheapest conditions first in `require` chains

## General Rules

1. **Never store private keys** in code or config — use environment variables
2. **Always verify contracts** on block explorers after deployment
3. **Record every deployment** in `deploys.ts` with address, args, and verify command
4. **Test on testnet first** — Amoy (Polygon), Saigon (Ronin), Base Sepolia before mainnet
5. **Run Slither** (`npm run lint`) before any mainnet deployment
6. **Optimizer enabled** at 200 runs for all production deployments
7. **Include deadline parameters** in all signature-gated functions
8. **Emit events** for all state-changing operations — indexers depend on them
