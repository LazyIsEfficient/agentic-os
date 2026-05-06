# Velocity Control (Rate Limiting)

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

## Interval Rolling Window Logic

```solidity
function getIntervalAllowedAmount(VelocityControl storage vc) internal view returns (uint256) {
    if (block.timestamp >= vc.intervalStart + vc.interval) {
        return vc.intervalLimit; // New period, full allowance
    }
    return vc.intervalLimit - vc.intervalClaimed; // Remaining in current period
}
```
