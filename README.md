# EventTicketNFT

An NFT ticket smart contract that allows minting with ETH or ERC20 tokens.

## Features
- Mint NFT tickets with ETH or ERC20 tokens
- Max supply: 100 tickets
- Max 5 tickets per wallet
- Owner can withdraw funds
- Complete test coverage

## Deployment on Sepolia

```bash
# Install dependencies
forge install

# Run tests
forge test

# Deploy to Sepolia
forge script script/DeployEventTicketNFT.s.sol --rpc-url sepolia --broadcast --verify
