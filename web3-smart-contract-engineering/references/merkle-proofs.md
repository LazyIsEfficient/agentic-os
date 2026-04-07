# Merkle Proof Verification

Used in `StakingVault` (deposits) and `AllocationModule` (claims):

```solidity
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Single-param leaf (deposit cap)
bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxAllowed));
require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

// Multi-param leaf (claim)
bytes32 leaf = keccak256(abi.encode(token, index, account, tokenAmount, tokenRefund));
require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
```

## TypeScript Merkle Tree Generation

Using `merkletreejs`:

```typescript
import { MerkleTree } from 'merkletreejs'
import { keccak256, solidityPacked } from 'ethers'

const leaves = allocations.map((a) =>
  keccak256(solidityPacked(
    ['address', 'uint256', 'uint256', 'uint256'],
    [a.address, a.index, a.tokenAmount, a.tokenRefund],
  ))
)

const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })
const root = tree.getHexRoot()
const proof = tree.getHexProof(leaves[index])
```
