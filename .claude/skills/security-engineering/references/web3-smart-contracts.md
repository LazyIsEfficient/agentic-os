# Web3 Smart Contract Security

## Required Security Patterns

Every production contract must use:

1. **ReentrancyGuard** — `nonReentrant` on all token/ETH transfer functions
2. **Pausable** — `whenNotPaused` on user-facing operations; admin can emergency-pause
3. **AccessControl** — Role-based permissions for multi-actor contracts
4. **SafeERC20** — For all `transfer`/`transferFrom`/`approve` calls
5. **ECDSA verification** — Via OpenZeppelin only, never custom implementations

## Signature Verification Rules

```solidity
bytes32 hash = keccak256(abi.encodePacked(
    block.chainid,       // Prevent cross-chain replay
    address(this),       // Prevent cross-contract replay
    msg.sender,          // Prevent signature forwarding
    claimId,
    amount,
    asset,
    deadline             // Time-bound
));

bytes32 ethSignedHash = hash.toEthSignedMessageHash();
address recovered = ethSignedHash.recover(signature);
require(recovered == authorizedSigner, "Invalid signature");

// Replay prevention
require(!usedHashes[ethSignedHash], "Already claimed");
usedHashes[ethSignedHash] = true;
```

**Mandatory elements in signed data**:
- `block.chainid` — cross-chain replay prevention
- `address(this)` — cross-contract replay prevention
- `deadline` or `blockNumberDeadline` — time-bounded validity
- Per-claim unique identifier (claimId, paymentCode hash)

## Rate Limiting (On-Chain)

```solidity
struct VelocityControl {
    uint256 maxPerClaim;        // Per-transaction limit
    uint256 maxTotalClaimed;    // Lifetime limit
    uint256 intervalLimit;      // Per-interval ceiling
    uint256 interval;           // Time period (seconds)
    bool enabled;
}
```

Plus per-token daily limits: `dailyTokenWithdrawals[currentDay][asset]`

## Smart Contract Audit Findings

A representative third-party audit of platform contracts surfaced findings across these recurring themes (illustrative, not exhaustive):

| Theme | Examples |
|---|---|
| **Frontrunning** | Pool initialization frontrun + zero slippage |
| **Accounting bugs** | Recipient removal corrupts totalShare, index collision in merkle claims |
| **DoS vectors** | Unsafe iteration in recipient management, division by zero |
| **Missing validation** | Missing merkle totals validation, missing refund cap check |
| **Access control gaps** | FeeModule.collect lacks access control |
| **Governance** | No timelock for privileged admin functions |
| **Best practices** | Missing `_disableInitializers()`, signature lacks domain separation (EIP-712) |

## Slither Static Analysis

Run before every mainnet deployment:

```bash
npm run lint  # Runs Slither analysis
```
