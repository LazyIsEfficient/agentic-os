# Smart Contract Testing

## Hardhat + Chai + Ethers.js

```typescript
import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Faucet Contract', function () {
  let mockERC20: CollateralizedToken
  let signer: Signer
  let bob: Signer

  before(async function () {
    const signers = await ethers.getSigners()
    signer = signers[0]

    bob = ethers.Wallet.createRandom().connect(signer.provider)
    await signer.sendTransaction({
      to: await bob.getAddress(),
      value: ethers.parseEther('1.0'),
    })

    const tokenFactory = await ethers.getContractFactory('CollateralizedToken')
    mockERC20 = await tokenFactory.deploy('Test Token', 'TEST')
    await mockERC20.waitForDeployment()
  })

  it('enforces withdraw limit', async function () {
    const decimals = await mockERC20.decimals()
    const limit = BigInt(10 ** Number(decimals)) * 1000n

    const factory = await ethers.getContractFactory('Faucet')
    const faucet = await factory.connect(signer).deploy(limit, await mockERC20.getAddress())
    await faucet.waitForDeployment()

    expect(await faucet.withdrawLimit()).to.equal(limit)

    await mockERC20.transfer(await faucet.getAddress(), limit * 2n)
    await faucet.connect(bob).faucet()

    expect(await mockERC20.balanceOf(await bob.getAddress())).to.equal(limit)
  })
})
```

## Time Manipulation

```typescript
import * as helpers from '@nomicfoundation/hardhat-network-helpers'

const currentTime = await helpers.time.latest()
await helpers.time.increase(3600)       // advance 1 hour
await helpers.time.increaseTo(target)   // advance to specific timestamp
await helpers.mine(10)                  // mine 10 blocks
```

## Event Assertions

```typescript
await expect(proxy.executeProposal(1))
  .to.emit(proxy, 'ProposalExecuted')
  .withArgs(1, owner.address)
```
