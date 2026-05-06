# Role-Based Proxy and Factory Patterns

## Role-Based Proxy (Multi-Sig Governance)

Per-role, per-method approval thresholds:

```solidity
contract RoleBasedProxy is AccessControl, Pausable, ReentrancyGuard {
    struct Proposal {
        uint256 id;
        address target;
        bytes data;
        bytes4 method;            // Function selector
        bytes32 requiredRole;
        uint256 approvals;
        bool executed;
    }

    mapping(bytes32 => mapping(bytes4 => mapping(address => bool))) public allowedMethods;
    mapping(bytes32 => mapping(bytes4 => uint256)) public approvalThresholds;

    function submitProposal(bytes32 role, address target, bytes calldata data) external {
        bytes4 method = bytes4(data[:4]);
        require(allowedMethods[role][method][target], "Method not allowed");
        // Auto-counts proposer's approval
    }

    function executeProposal(uint256 proposalId) external {
        require(proposal.approvals >= threshold, "Insufficient approvals");
        (bool success,) = proposal.target.call(proposal.data);
        require(success, "Execution failed");
    }
}
```

## Factory Pattern (RewardPayout)

```solidity
contract RewardPayoutFactory is AccessControl {
    mapping(address => bool) public isPayoutContract;
    address[] public allPayoutContracts;

    function createPayoutContract(address signer, address admin) external onlyRole(ADMIN_ROLE)
        returns (address)
    {
        RewardPayout payout = new RewardPayout(signer, admin);
        isPayoutContract[address(payout)] = true;
        allPayoutContracts.push(address(payout));
        return address(payout);
    }

    // Batch admin operations across all vaults
    function batchWhitelistAsset(address[] calldata contracts, address asset) external { ... }
    function batchPauseContracts(address[] calldata contracts) external { ... }
    function batchAdminWithdraw(address[] calldata contracts, address[] calldata assets) external { ... }
}
```
