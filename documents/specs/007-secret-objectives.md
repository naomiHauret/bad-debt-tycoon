# Secret player objectives

## User stories

### Resource-based objectives

**As a player assigned a resource objective**,
I want to **accumulate the required amount of lives/coins/both**,
So that **I can exit early as a winner before the exit window**.

#### Resource - Lives

- Target: `exitLivesRequired * multiplier` (1x, 2x, or 3x)
- Verification: Check player's current lives >= target (onchain)

Eg: Tournament requires 3 lives to exit, 2x multiplier -> need 6 lives

#### Resource - Coins

- Target: `exitCoinCost * multiplier` (0.5x to 3x)
- Verification: Check player's current coins >= target (onchain)

Eg: Exit cost is 100 coins, 2.5x multiplier -> need 250 coins

#### Resource - All

- Target: Both lives AND coins multipliers
- Verification: Check both thresholds met (onchain)

Eg: Need 6 lives (2x) AND 200 coins (2x)

---

### Combat-based objectives (tracked offchain)

**As a player assigned a combat objective**,
I want to **achieve the required combat performance**,
So that **I can exit early as a winner**.

#### Elimination count

- Target: `(cardsPerType * 3 * percentage) / 100` eliminations
- Percentages: 25%, 50%, 75%, 100%
- Verification: Backend tracks eliminations, player posts proof onchain

Eg: 4 cards/type, 50% -> eliminate 6 players

#### Battle rate

- Target: `(playerCount * percentage) / 100` battles (win or lose)
- Percentages: 10%, 20%, 30%
- Verification: Backend tracks battle count, player posts proof

Eg: 20 players, 20% -> participate in 4 battles

#### Win streak

- Target: `(cardsPerType * 3 * percentage) / 100` consecutive wins
- Percentages: 15%, 25%, 35%, 50%
- Verification: Backend tracks win sequences, player posts proof

Eg: 4 cards/type, 25% -> win 3 fights in a row

#### Lose streak

- Target: `(cardsPerType * 3 * percentage) / 100` consecutive losses
- Percentages: 15%, 25%, 35%, 50%
- Verification: Backend tracks loss sequences, player posts proof

Eg: 4 cards/type, 35% -> lose 4 fights in a row

#### Victory rate

- Target: Win >= X% of all battles
- Percentages: 60%, 70%, 80%, 90%, 100%
- Verification: Backend calculates win rate, player posts proof

Eg: Fight 10 times, win 8 -> 80% win rate

#### Perfect record

- Target: Win ALL fights OR lose ALL fights
- Verification: Backend confirms no losses (or no wins), player posts proof

Eg: Fight 5 times, win 5 -> perfect win record

---

### Trade-based objectives (offchain)

**As a player assigned a trade objective**,
I want to **complete the required number/volume of trades**,
So that **I can exit early as a winner**.

#### Trade count

- Target: `((playerCount - 1) * percentage) / 100` trades
- Percentages: 10%, 20%, 30%
- Verification: Backend tracks completed trades, player posts proof

Eg: 20 players, 20% -> complete 4 trades

#### Trade volume

- Target: Trade away `(initialCoins * percentage) / 100` coins total
- Percentages: 25%, 50%, 75%, 100%, 150%
- Verification: Backend tracks cumulative coins traded, player posts proof

Eg: Start with 1000 coins, 75% -> trade 750 coins total

---

## Technical breakdown

Secret objectives are optional win conditions assigned randomly to players at tournament start. They are completely generic and composable to offer as much flexibility, replayability and challenge as possible. Completing an objective allows the player to exit the game (before the exit window opens) as a winner, as long as they meet the other standard exit requirements (lives, coins, cards).

**How it works:**

- One objective per player, assigned randomly at tournament start
- Objectives scale with tournament parameters (cards, players, exit requirements)
- Players can sell their objective information to others
- Completion is tracked offchain (backend), verified onchain when claiming early exit

### Objective definition structure

```solidity
enum ObjectiveType {
    ResourceLives, // Accumulate X lives
    ResourceCoins, // Accumulate X coins
    ResourceAll, // Accumulate X lives AND X coins
    EliminationCount, // Eliminate X players
    BattleRate, // Fight with X% of players
    WinStreak, // Win X fights in a row
    LoseStreak, // Lose X fights in a row
    VictoryRate, // Win >= X% of all fights
    PerfectRecord, // Win all OR lose all fights
    TradeCount, // Complete X trades
    TradeVolume // Trade X coins total
}

enum ResourceType {
    Lives,
    Coins,
    All
}

struct ObjectiveDefinition {
    uint8 objectiveId;
    ObjectiveType objectiveType;
    bytes targetData; // Encoded target parameters
    bool exists;
}
```

### Target data encoding

**ResourcebBased (Lives/Coins/All):**

```solidity
// targetData = abi.encode(uint8 multiplierBPS)
// multiplierBPS: 50 = 0.5x, 100 = 1x, 200 = 2x, 300 = 3x

// Lives: 100, 200, 300 (1x, 2x, 3x)
// Coins: 50, 100, 150, 200, 250, 300 (0.5x to 3x)
// All: abi.encode(uint8 livesMultiplier, uint8 coinsMultiplier)
```

**Combat count/streak (Elimination, WinStreak, LoseStreak):**

```solidity
// targetData = abi.encode(uint8 percentage)
// percentage: 25, 50, 75, 100 (for elimination/streak)
```

**Combat rate (Battle, Victory):**

```solidity
// BattleRate: abi.encode(uint8 percentage)
// percentage: 10, 20, 30

// VictoryRate: abi.encode(uint8 percentage)
// percentage: 60, 70, 80, 90, 100
```

**Perfect record:**

```solidity
// targetData = abi.encode(bool mustWinAll)
// true = win all fights, false = lose all fights
```

**Trade-based:**

```solidity
// TradeCount: abi.encode(uint8 percentage)
// percentage: 10, 20, 30

// TradeVolume: abi.encode(uint8 percentage)
// percentage: 25, 50, 75, 100, 150
```
