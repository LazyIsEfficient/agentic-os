# Signature Verification

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

## TypeScript Signature Generation (Tests/Backend)

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
