@doing

# Player resources

Each player's resources are tracked throughout the tournament lifecycle.

## User stories breakdown

### Resource tracking

**As a player that staked the required amount of tokens**,
I want to **automatically receive my resources**,
So that I can **participate in the game**.

```
GIVEN I am a recorded player in the tournament contract
WHEN I am added to players mapping
  THEN my initial resources are recorded:
    - lives = `initialLives`
    - coins = `stakeAmount` * `coinConversionRate`
    - cards = `cardsPerType` for each type (rock, paper, scissors)
```

## Technical breakdown

Player resources management tracking is built-in the `Tournament` system, which automatically allocates the required game resources to players once their participation is confirmed.

When players join a tournament, their stake converts to in-game currency (configured by the game designer), which establishes both their starting balance and the reference point for calculating their personal exit cost (see Economic Collapse specification for more details on those mechanisms).

The player's coin amount initial value becomes immutable, and determines their minimum exit threshold throughout the tournament.

Their stake amount is also important, not only to issue refund or allow pre-game withdrawal, but also to calculate how many % of their stake the player can get back if they are allowed to forfeit.

## System requirements

### `PlayerResources` data structure

**Immutable references (set once when joining):**

- `initialCoins`: Calculated as stake amount \* coin conversion rate
- `stakeAmount`: Original token amount deposited

**Mutable gameplay state:**

- `coins`: Current coins (affected by decay, trades, loans, mystery cards)
- `lives`: Gained from wins, lost from losses
- `totalCards`: Total cards in hand (rock+paper+scissors combined)
- `lastDecayTimestamp`: Checkpoint for calculating accumulated decay (see Economic Collapse specs for more details)

**Status tracking:**

- `status`: player status (`PlayerStatus` enum), can be `Active`, `Exited`, `Forfeited`, `PrizeClaimed`, `Refunded`
- `exists`: Flag to track if player has joined to prevent duplicate joins

## Errors

- `PlayerNotFound()`: When address has not joined tournament
- `PlayerAlreadyJoined()`: When attempting to join tournament more than once
- `TournamentLocked()`: When `maxPlayers` threshold is reached
- `CannotExit()`: player doesn't meet requirements (amount of lives/coins)
- `ForfeitNotAllowed()`: tournament doesn't allow players to forfeit
