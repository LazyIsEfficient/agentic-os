# Key Data Models

## Points Ledger

```
PointTransaction {
  pointAmount, transactionType (CREDIT | DEBIT),
  status (in_progress | completed),
  distributedAt,
  userId → User,
  activityId → Activity (nullable),
  tokenId → Token (nullable),
  boostId → Boost (nullable)
}
```

## Allocation State Machine

```
NULL → COMMITTING → CLAIMABLE → REFUNDED

UserCommitment   — Records each wallet's committed amount + points
UserClaimRefund  — Records claim or refund events (eventType: Claimed | Refunded)
AllocationPool   — Uniswap V3 pool parameters (sqrtPriceX96, ticks, liquidity)
```

## Activity / Quest System

```
Activity {
  slug, frequency (oneTime | unlimited | daily | weekly),
  rewards (points), published, featured,
  tasks[] (ActivityTask: internalAction | gameAction | enrollAction)
}

UserActivity {
  state (in_progress | completed | rewarded),
  enrolledAt, completedAt
}
```
