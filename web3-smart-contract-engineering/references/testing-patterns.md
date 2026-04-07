# Testing Patterns

## Hardhat + Chai + Ethers.js v6

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

## Time Manipulation

```typescript
import * as helpers from '@nomicfoundation/hardhat-network-helpers'

// Advance time for expiry/deadline testing
const currentTime = await helpers.time.latest()
await helpers.time.increase(3600) // 1 hour
await helpers.time.increaseTo(currentTime + 86400) // specific timestamp

// Mine blocks
await helpers.mine(10)
```

## Signature Testing

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

## Merkle Proof Testing

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
