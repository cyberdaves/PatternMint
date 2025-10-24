;; PatternMint - Visual Pattern Puzzle NFT Rewards System
;; A smart contract for solving pattern puzzles and minting generative NFTs

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-solved (err u102))
(define-constant err-wrong-answer (err u103))
(define-constant err-puzzle-inactive (err u104))
(define-constant err-mint-failed (err u105))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var last-puzzle-id uint u0)

;; NFT Definition
(define-non-fungible-token pattern-nft uint)

;; Data Maps
(define-map puzzles
  uint
  {
    pattern-hash: (buff 32),
    difficulty: uint,
    reward-points: uint,
    active: bool,
    creator: principal
  }
)

(define-map puzzle-solutions
  { puzzle-id: uint, solver: principal }
  {
    solved: bool,
    token-id: uint,
    timestamp: uint
  }
)

(define-map user-stats
  principal
  {
    puzzles-solved: uint,
    total-points: uint,
    nfts-minted: uint
  }
)

(define-map nft-metadata
  uint
  {
    puzzle-id: uint,
    solver: principal,
    pattern-seed: uint,
    difficulty: uint,
    mint-time: uint
  }
)

;; Read-only functions
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-read-only (get-last-puzzle-id)
  (ok (var-get last-puzzle-id))
)

(define-read-only (get-puzzle (puzzle-id uint))
  (ok (map-get? puzzles puzzle-id))
)

(define-read-only (get-user-stats (user principal))
  (ok (default-to
    { puzzles-solved: u0, total-points: u0, nfts-minted: u0 }
    (map-get? user-stats user)
  ))
)

(define-read-only (get-nft-metadata (token-id uint))
  (ok (map-get? nft-metadata token-id))
)

(define-read-only (has-solved-puzzle (puzzle-id uint) (user principal))
  (ok (is-some (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: user })))
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? pattern-nft token-id))
)

(define-read-only (get-token-uri (token-id uint))
  (ok (some "ipfs://patternmint/{id}"))
)

;; Private functions
(define-private (increment-token-id)
  (let ((current-id (var-get last-token-id)))
    (var-set last-token-id (+ current-id u1))
    current-id
  )
)

(define-private (increment-puzzle-id)
  (let ((current-id (var-get last-puzzle-id)))
    (var-set last-puzzle-id (+ current-id u1))
    current-id
  )
)

(define-private (update-user-stats (user principal) (points uint))
  (let (
    (current-stats (default-to
      { puzzles-solved: u0, total-points: u0, nfts-minted: u0 }
      (map-get? user-stats user)
    ))
  )
  (map-set user-stats user {
    puzzles-solved: (+ (get puzzles-solved current-stats) u1),
    total-points: (+ (get total-points current-stats) points),
    nfts-minted: (+ (get nfts-minted current-stats) u1)
  })
  )
)

;; Public functions

;; Create a new puzzle
(define-public (create-puzzle (pattern-hash (buff 32)) (difficulty uint) (reward-points uint))
  (let (
    (puzzle-id (increment-puzzle-id))
  )
  (asserts! (is-eq tx-sender contract-owner) err-owner-only)
  (map-set puzzles puzzle-id {
    pattern-hash: pattern-hash,
    difficulty: difficulty,
    reward-points: reward-points,
    active: true,
    creator: tx-sender
  })
  (ok puzzle-id)
  )
)

;; Solve puzzle and mint NFT
(define-public (solve-puzzle (puzzle-id uint) (answer (buff 32)))
  (let (
    (puzzle (unwrap! (map-get? puzzles puzzle-id) err-not-found))
    (already-solved (is-some (map-get? puzzle-solutions { puzzle-id: puzzle-id, solver: tx-sender })))
    (token-id (+ (var-get last-token-id) u1))
    (pattern-seed (+ puzzle-id stacks-block-height))
  )
  ;; Validations
  (asserts! (get active puzzle) err-puzzle-inactive)
  (asserts! (not already-solved) err-already-solved)
  (asserts! (is-eq (get pattern-hash puzzle) (sha256 answer)) err-wrong-answer)
  
  ;; Mint NFT
  (unwrap! (nft-mint? pattern-nft token-id tx-sender) err-mint-failed)
  
  ;; Record solution
  (map-set puzzle-solutions 
    { puzzle-id: puzzle-id, solver: tx-sender }
    {
      solved: true,
      token-id: token-id,
      timestamp: stacks-block-height
    }
  )
  
  ;; Store NFT metadata
  (map-set nft-metadata token-id {
    puzzle-id: puzzle-id,
    solver: tx-sender,
    pattern-seed: pattern-seed,
    difficulty: (get difficulty puzzle),
    mint-time: stacks-block-height
  })
  
  ;; Update user stats
  (update-user-stats tx-sender (get reward-points puzzle))
  
  ;; Increment token ID
  (var-set last-token-id token-id)
  
  (ok token-id)
  )
)

;; Transfer NFT
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-owner-only)
    (nft-transfer? pattern-nft token-id sender recipient)
  )
)

;; Deactivate puzzle (admin only)
(define-public (deactivate-puzzle (puzzle-id uint))
  (let (
    (puzzle (unwrap! (map-get? puzzles puzzle-id) err-not-found))
  )
  (asserts! (is-eq tx-sender contract-owner) err-owner-only)
  (map-set puzzles puzzle-id (merge puzzle { active: false }))
  (ok true)
  )
)

;; Burn NFT (optional feature)
(define-public (burn (token-id uint))
  (let (
    (owner (unwrap! (nft-get-owner? pattern-nft token-id) err-not-found))
  )
  (asserts! (is-eq tx-sender owner) err-owner-only)
  (nft-burn? pattern-nft token-id owner)
  )
)