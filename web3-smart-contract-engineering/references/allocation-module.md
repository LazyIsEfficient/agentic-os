# Allocation Module (Token Launch System)

State machine for token commitments, claims, and refunds:

```solidity
enum AllocState { NULL, COMMITTING, CLAIMABLE, REFUNDED }

struct AllocData {
    AllocState state;
    uint160 sqrtPriceX96;        // Uniswap V3 initial price
    uint24 uniV3Fee;             // Pool fee tier (500, 3000, 10000)
    uint256 targetRaise;         // Target amount in base token
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

## Lifecycle

1. Owner creates allocation with parameters
2. Users commit the base token during `commitStartTime..commitEndTime` (signed quota)
3. Admin sets merkle root → state transitions to `CLAIMABLE`
4. Users claim new tokens + base-token refunds via merkle proof
5. If admin misses deadline → auto-transitions to `REFUNDED`

## Advanced Features

- **CREATE2 deterministic token deployment**: Pre-calculate token address
- **Uniswap V3 LP creation**: Full-range position minted on state transition
- **EIP-712 style signed quotas**: Off-chain allocation verification
