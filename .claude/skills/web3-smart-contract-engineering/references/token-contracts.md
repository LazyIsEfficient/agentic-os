# Token Contracts

## MintableERC721

Ownable, pausable, single-minter with batch support:

```solidity
contract MintableERC721 is ERC721URIStorage, Ownable, ERC721Pausable {
    address public minter;
    uint256 private currentTokenId;
    mapping(uint256 => bool) public mintingStopped;

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    function mint(address to, string memory uri) public onlyMinter returns (uint256) {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        _setTokenURI(currentTokenId, uri);
        return currentTokenId;
    }

    function mintBatch(address to, uint256 count) public onlyMinter { ... }
    function stopMinting(uint256[] calldata ids) external onlyOwner { ... }
}
```

## MintableERC1155 (Soulbound)

Non-transferable, all transfer methods revert:

```solidity
contract MintableERC1155 is ERC1155Pausable, Ownable {
    mapping(uint256 => bool) public mintingStopped;

    modifier onlyUnstopped(uint256 id) {
        require(!mintingStopped[id], "Minting stopped for this id");
        _;
    }

    // All transfers blocked — soulbound tokens
    function safeTransferFrom(...) public pure override { revert("Non-transferable"); }
    function safeBatchTransferFrom(...) public pure override { revert("Non-transferable"); }
}
```

## CollateralizedToken

ERC20 backed by multiple collateral tokens with nested redemption:

```solidity
struct CollateralConfig {
    bool enabled;
    bool isNestedCollateralToken;
    uint256 index;
    address token;
}

function redeem(uint256 amount, bool unwrap_nested, address beneficiary) public {
    uint256 share;
    for (uint i = 0; i < collateralTokens.length; i++) {
        CollateralConfig memory config = collateralConfigs[collateralTokens[i]];
        if (!config.enabled) continue;

        share = IERC20(config.token).balanceOf(address(this)) * amount / totalSupply();

        if (config.isNestedCollateralToken && unwrap_nested) {
            CollateralizedToken(config.token).redeem(share, unwrap_nested, beneficiary);
        } else {
            IERC20(config.token).transfer(beneficiary, share);
        }
    }
    _burn(msg.sender, amount);
}
```
