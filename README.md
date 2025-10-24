# PatternMint 🎨

A decentralized rewards system built on the Stacks blockchain that allows users to solve visual pattern puzzles and earn unique generative NFTs as rewards.

## Overview

PatternMint combines puzzle-solving with NFT creation. Each time a user successfully solves a pattern puzzle, they automatically mint a unique generative NFT that's tied to that specific puzzle and moment in time. The system tracks user achievements and prevents duplicate solutions.

## Features

### 🧩 Puzzle System
- Create visual pattern puzzles with varying difficulty levels
- Each puzzle has a cryptographic hash for secure solution verification
- Admin-controlled puzzle activation/deactivation
- Reward points system based on difficulty

### 🎨 Generative NFTs
- Automatic NFT minting upon successful puzzle solving
- Each NFT contains unique metadata including:
  - Puzzle ID
  - Solver address
  - Pattern seed (generated from puzzle ID + block height)
  - Difficulty level
  - Mint timestamp
- NFTs are fully transferable between users

### 📊 User Statistics
- Track total puzzles solved
- Monitor accumulated reward points
- Count of NFTs minted
- Prevent users from solving the same puzzle twice

## Smart Contract Functions

### Read-Only Functions

#### `get-last-token-id`
Returns the ID of the most recently minted NFT.
```clarity
(get-last-token-id)
```

#### `get-last-puzzle-id`
Returns the ID of the most recently created puzzle.
```clarity
(get-last-puzzle-id)
```

#### `get-puzzle (puzzle-id uint)`
Retrieves puzzle details by ID.
```clarity
(get-puzzle u1)
```

#### `get-user-stats (user principal)`
Returns statistics for a specific user.
```clarity
(get-user-stats 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### `has-solved-puzzle (puzzle-id uint) (user principal)`
Checks if a user has already solved a specific puzzle.
```clarity
(has-solved-puzzle u1 tx-sender)
```

#### `get-nft-metadata (token-id uint)`
Returns metadata for a specific NFT.
```clarity
(get-nft-metadata u1)
```

#### `get-owner (token-id uint)`
Returns the current owner of an NFT.
```clarity
(get-owner u1)
```

#### `get-token-uri (token-id uint)`
Returns the metadata URI for an NFT.
```clarity
(get-token-uri u1)
```

### Public Functions

#### `create-puzzle (pattern-hash (buff 32)) (difficulty uint) (reward-points uint)`
**Admin Only** - Creates a new puzzle.

Parameters:
- `pattern-hash`: SHA256 hash of the correct answer
- `difficulty`: Difficulty level (1-10 recommended)
- `reward-points`: Points awarded for solving

```clarity
(contract-call? .PatternMint create-puzzle 0x1234... u5 u100)
```

#### `solve-puzzle (puzzle-id uint) (answer (buff 32))`
Attempts to solve a puzzle and mint an NFT if successful.

Parameters:
- `puzzle-id`: ID of the puzzle to solve
- `answer`: User's answer (will be hashed and compared)

```clarity
(contract-call? .PatternMint solve-puzzle u1 0x616e73776572)
```

#### `transfer (token-id uint) (sender principal) (recipient principal)`
Transfers an NFT to another user.

```clarity
(contract-call? .PatternMint transfer u1 tx-sender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

#### `deactivate-puzzle (puzzle-id uint)`
**Admin Only** - Deactivates a puzzle to prevent further solving.

```clarity
(contract-call? .PatternMint deactivate-puzzle u1)
```

#### `burn (token-id uint)`
Allows NFT owners to burn their tokens.

```clarity
(contract-call? .PatternMint burn u1)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | err-owner-only | Action requires contract owner/NFT owner |
| u101 | err-not-found | Puzzle or NFT not found |
| u102 | err-already-solved | User has already solved this puzzle |
| u103 | err-wrong-answer | Incorrect puzzle solution |
| u104 | err-puzzle-inactive | Puzzle is not active |
| u105 | err-mint-failed | NFT minting failed |

## Deployment

### Prerequisites
- Clarinet installed
- Stacks wallet configured
- STX tokens for deployment

### Steps

1. Clone the repository
```bash
git clone <repository-url>
cd patternmint
```

2. Test the contract
```bash
clarinet test
```

3. Deploy to testnet
```bash
clarinet deploy --testnet
```

4. Deploy to mainnet
```bash
clarinet deploy --mainnet
```

## Usage Example

### Creating a Puzzle (Admin)

1. Generate a pattern answer
2. Hash the answer using SHA256
3. Call `create-puzzle` with the hash

```javascript
// Example: Answer is "CIRCLE-SQUARE-TRIANGLE"
const answer = "CIRCLE-SQUARE-TRIANGLE";
const hash = sha256(answer); // 0x1234abcd...

// Deploy puzzle
await createPuzzle(hash, 5, 100);
```

### Solving a Puzzle (User)

1. Find the puzzle ID
2. Determine the correct answer
3. Call `solve-puzzle` with your answer

```javascript
const puzzleId = 1;
const answer = "CIRCLE-SQUARE-TRIANGLE";

// This will automatically mint an NFT if correct
await solvePuzzle(puzzleId, answer);
```

## Data Structures

### Puzzle
```clarity
{
  pattern-hash: (buff 32),
  difficulty: uint,
  reward-points: uint,
  active: bool,
  creator: principal
}
```

### NFT Metadata
```clarity
{
  puzzle-id: uint,
  solver: principal,
  pattern-seed: uint,
  difficulty: uint,
  mint-time: uint
}
```

### User Stats
```clarity
{
  puzzles-solved: uint,
  total-points: uint,
  nfts-minted: uint
}
```

## Security Features

- **SHA256 Verification**: Puzzle solutions are verified using cryptographic hashing
- **Duplicate Prevention**: Users cannot solve the same puzzle twice
- **Owner Controls**: Admin functions restricted to contract owner
- **Transfer Validation**: Only NFT owners can transfer their tokens

## Roadmap

- [ ] Implement puzzle hints system
- [ ] Add difficulty-based reward multipliers
- [ ] Create leaderboard functionality
- [ ] Integrate IPFS for NFT metadata storage
- [ ] Add puzzle time limits
- [ ] Implement collaborative puzzle solving

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## License

This smart contract is open source and available for educational purposes.

## Support

For questions or issues:
- Open an issue on GitHub

## Acknowledgments

Built on the Stacks blockchain using Clarity smart contract language.

---

**Note**: This is a beta version. Please audit the code thoroughly before deploying to mainnet with real assets.