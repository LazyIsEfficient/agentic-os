# Security Rules

## Required Patterns

1. **ReentrancyGuard** — on all functions that transfer tokens or ETH
2. **Pausable** — on all user-facing operations; owner can emergency-pause
3. **AccessControl** — for multi-role permission systems (prefer over `Ownable` for complex contracts)
4. **SafeERC20** — for all `transfer` / `transferFrom` / `approve` calls
5. **ECDSA signature verification** — always via OpenZeppelin, never custom
6. **Replay protection** — `usedHashes` mapping on every signature-gated function
7. **Cross-chain replay prevention** — include `block.chainid` and `address(this)` in signed data
8. **Merkle proof verification** — via `MerkleProof.verify` from OpenZeppelin

## Rate Limiting

Use velocity controls for any claim/payout function:
- Per-transaction max (`maxPerClaim`)
- Lifetime max (`maxTotalClaimed`)
- Rolling time-interval limits (`intervalLimit` / `interval`)
- Per-token daily limits
- Hard expiry deadlines

## Access Control

- Single-owner contracts: `Ownable` with `onlyOwner`
- Multi-role contracts: `AccessControl` with granular roles
- Multi-sig operations: `RoleBasedProxy` with per-method approval thresholds
- Minter pattern: Dedicated `minter` address with `onlyMinter` modifier

## Token Safety

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
