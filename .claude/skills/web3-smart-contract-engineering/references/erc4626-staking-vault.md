# ERC4626 Staking Vault

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
