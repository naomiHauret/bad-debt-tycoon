# Collapsing economy

## User stories breakdown

### Decay system (passive pressure)

**As the game system**,
I want to **automatically drain the in-game currency of all active players at regular intervals**,
So that **players are forced to act rather than wait passively**.

```
GIVEN a tournament is in "Active" status
  AND decay is configured with:
    - decayAmount (eg 10 coins)
    - decayInterval (eg 1200 seconds = 20 minutes)
WHEN time passes
THEN every `decayInterval` seconds, each active player loses `decayAmount` coins
  AND coins cannot go below 0 (clamped)
  AND decay is calculated using lazy evaluation (not applied until needed)
```

**As an active player**,
I want to **see my current coins after decay**,
So that I can **make informed decisions about playing, trading and exiting**.

```
GIVEN I am an active player
  AND some time has passed since last decay update
WHEN I call `Tournament.getCurrentPlayerState(myAddress)` (view function)
THEN my current coins are calculated as:
  coins = storedCoins - (decayAmount * intervalsPassed)
  WHERE intervalsPassed = (block.timestamp - lastDecayTimestamp) / decayInterval
  AND coins = max(0, coins) (cannot be negative)
  AND this calculation does NOT modify storage
```

**As an active player**,
I want **decay to be automatically applied when I perform actions**,
So that **my state is always up-to-date**.

```
GIVEN I am an active player
  AND I perform any state-changing action (exit, forfeit, trade, fight, etc.)
WHEN the transaction executes
THEN decay is automatically applied first via `_applyDecay(msg.sender)`
  AND my `coins` storage value is updated
  AND my `lastDecayTimestamp` is updated to current block.timestamp
  AND `DecayApplied(player, totalDecay, remainingCoins)` event is emitted
  AND THEN my intended action executes
```

### Exit cost system (active barrier)

**As the game system**,
I want to **increase the exit cost over time using compound growth**,
So that **players cannot simply sell everything and exit immediately**.

```
GIVEN a tournament is in "Active" status
  AND exit cost is configured with:
    - exitCostBasePercentBPS (eg 5000 = 50% of initial coins) (BPS = basis points)
    - exitCostCompoundRateBPS (eg 1000 = 10% per interval)
    - exitCostInterval (eg 3600 seconds = 1 hour)
WHEN calculating exit cost for a player
THEN exitCost = baseCost * (1 + compoundRate * intervals)
  WHERE:
    - baseCost = player.initialCoins * exitCostBasePercentBPS / 10000
    - intervals = (block.timestamp - actualStartTime) / exitCostInterval
    - compoundRate = exitCostCompoundRateBPS / 10000
  AND this is a view function (no storage modification)
```

**As an active player**,
I want to **check if I can afford to exit**,
So that I know **whether I should accumulate more coins or exit now**.

```
GIVEN I am an active player
WHEN I call `Tournament.calculateExitCost(myAddress)` (view function)
THEN I receive the current exit cost in coins
  AND I can compare this to my current coins (after decay)
  AND I know if I meet the exit requirement: coins >= exitCost
```

### Collapse mechanism

**As the game system**,
I want **the gap between available coins and exit cost to close over time**,
So that **exit becomes more and more difficult, forcing players to act**.

```
GIVEN a tournament is configured with:
  - Duration: 4 hours
  - Initial coins: 400 (from 10 PYUSD * 40 rate)
  - Decay: 10 coins every 20 min (30 coins/hour)
  - Exit cost: 50% base (200) + 10% compound/hour
WHEN time progresses
THEN the economic state evolves as:

| Time | Coins (decay) | Exit cost (compound) | Gap  | Can exit? |
|------|---------------|----------------------|------|-----------|
| 0h   | 400           | 200                  | +200 |    Yes    |
| 1h   | 370           | 220                  | +150 |    Yes    |
| 2h   | 340           | 240                  | +100 |    Yes    |
| 3h   | 310           | 260                  | +50  |    Yes    |
| 4h   | 280           | 280                  | 0    |    Edge   |
| 5h   | 250           | 300                  | -50  |    No     |

AND the collapse occurs around hour 4-5
AND players are forced to: fight, trade, take loans, or forfeit
```

### Resource initialization

**As a player**,
I want to **receive initial resources when joining a tournament**,
So that I can **participate in the game**.

```
GIVEN a tournament is in "Open" status
  AND tournament parameters define:
    - coinConversionRate (eg 40 means 1 PYUSD = 40 coins)
    - initialLives (eg 5)
    - cardsPerType (eg 10)
WHEN I c overviewall `joinTournament(stakeAmount)`
  AND the transaction succeeds
THEN my player state is initialized as:
  - initialCoins = stakeAmount * coinConversionRate (immutable reference)
  - coins = initialCoins (mutable, affected by decay/trades/loans)
  - lives = initialLives
  - cardsRock = cardsPerType
  - cardsPaper = cardsPerType
  - cardsScissors = cardsPerType
  - debt = 0
  - lastDecayTimestamp = block.timestamp
  - hasExited = false
  - hasForfeited = false
```

### Exit validation

**As a player**,
I want the **system to validate all exit requirements including economic ones**,
So that **only players who meet all conditions can exit and the game stays fair**.

```
GIVEN I am an active player in an "Active" tournament
WHEN I call `Tournament.exit()`
THEN the system checks ALL of the following:
  - lives >= exitLivesRequired
  - cardsRock == 0 AND cardsPaper == 0 AND cardsScissors == 0
  - getCurrentCoins(msg.sender) >= calculateExitCost(msg.sender) (both after decay)
  - debt == 0

AND IF any condition fails
  THEN transaction reverts with specific error message

AND IF all conditions pass
  THEN I am marked as hasExited = true
  AND I am added to winners array
  AND `PlayerExited(player, exitTime)` event is emitted
```

## Technical breakdown

The collapsing economy operates as a dual-pressure system. Two independent (but complementary) forces drive players toward decisive action : decay and exit costs.

**Decay** acts as the universal drain, it's a a constant, **predictable loss affecting all players equally**. It establishes the baseline time pressure and ensures no player can indefinitely hoard resources without consequence. This passive mechanism requires no player interaction and operates automatically based on elapsed time.

**Exit cost** functions as the escalating toll. It's a growing requirement that compounds over time. Unlike decay which is absolute, **exit costs scale proportionally to each player's initial stake**, ensuring fairness across varied entry amounts.

The collapse emerges from divergence. While player in-game currency decreases linearly through decay, exit requirements grow exponentially through compounding. The gap between available resources and exit threshold narrows predictably, which means it's technically possible to calculate the point of no return/bottleneck (if the game designer implemented the tournament to work that way ).

The system enforces a deflanatory economy, with no new coins entering circulation after initialization. Trading redistributes existing coins, while decay removes them completely from circulation. Loans create obligations without generating value.

Resource initialization ties everything together, with the player starting balance (in-game currency amount derived from their stake amount \* conversion rate) being used as the reference to calculate their exit toll throughout the tournament.

### Mechanics design

- **Coin decay, the passive resource drain**

  - Linear, absolute loss
  - Applies to all active players equally
  - Can reduce coins to zero (hard deadline)

- **Exit cost, the active barrier**

  - Exponential growth (simplified compound)
  - Scales with player's initial stake (fairness)
  - Creates urgency without being instantly impossible
  - Increases pressure over time

- **Deflanatory in-game currency**: the in-game currency has a fixed supply and is only updated through decay

## System requirements

Both decay and exit cost should calculate the current value on-demand, without storage writes ; additionally, state-modifying functions should **apply the decay first**, THEN execute whatever they are supposed to modify.
This means that (in theory) we shouldn't need cron/scheduled jobs to get accurate values throughout the game and could use the system contracts.

### Economic parameters (configured by the game designer)

Economic mechanics are configured via tournament parameters when creating a tournament. These parameters are immutable once set.

#### Decay parameters & config

- `decayAmount`: Fixed number of coins lost per interval (eg 10 coins)
- `decayInterval`: Time in seconds between decay applications (min 60 seconds)

**Validation constraints:**

- Decay amount must be positive (> 0)
- Decay interval must be at least 60 seconds
- Total possible decay over tournament duration must not exceed typical player starting coins (to prevents instant drain)

#### Exit cost parameters & config

> BPS stands for "Basis points". Basis points are a unit of measurement that represent one-hundredth of a percentage point (0.01%). They are commonly used to describe changes in interest rates or yields. 100 BPS = 1%.

- `exitCostBasePercentBPS`: Base exit cost as percentage of player's initial coins, in basis points (eg 5000 = 50%)
- `exitCostCompoundRateBPS`: Growth rate per interval in basis points (eg 1000 = 10% per interval)
- `exitCostInterval`: Time in seconds between cost compounds (minimum 60 seconds)

**Validation constraints:**

- Base percent must be positive (> 0)
- Base percent cannot exceed 100% (<= 10000 BPS)
- Compound rate cannot exceed 50% per interval (≤ 5000 BPS)
- Exit cost interval must be at least 60 seconds

Note: BPS = Basis Points, where 100 BPS = 1%. Used for precise percentage representation without decimals.

### Core economic functions

The `Tournament` contract having limited space, we should expose the inner logic of following functions for querying economic state and validating exit requirements in a dedicated library, `TournamentCalculations`, which `Tournament` will import and call:

`getCurrentCoins(address player)`

- **Type:** View function (read-only)
- **Purpose:** Calculate player's current coin balance after applying accumulated decay
- **Who uses it:** Anyone (players checking their balance, UI displaying state)
- **How it works:** Applies decay formula to stored coins based on time elapsed since last decay checkpoint. Can't be negative (clamped at 0)

`getCurrentPlayerResources(address player)`

- **Type:** View function (read-only)
- **Purpose:** Get complete player resourcs with all decay calculations applied
- **Who uses it:** Anyone (comprehensive state queries, UI dashboards)
- **How it works:** Reads stored state and applies decay calculations without modifying storage

`calculateExitCost(address player)`

- **Type:** View function (read-only)
- **Purpose:** Calculate current exit cost based on time elapsed and player's initial coins
- **Who uses it:** Anyone (players planning exit timing, UI displaying requirements)
- **Returns:** Exit cost in coins (grows over time via compound formula)
- **How it works:** Applies compound growth formula based on tournament start time and player's initial coins

`canExit(address player)`
**Type:** View function (read-only)

- **Purpose:** Check if player meets all exit requirements (lives, cards, coins, debt)
- **Who uses it:** Anyone (players checking eligibility, UI showing exit button state)
- **Returns:** Boolean indicating whether or not exiting is possible
- **How it works:** Validates all exit conditions including current coins VS exit cost after decay

`_applyDecay(address player)`

-**Type:** Internal function (state-modifying)

- **Purpose:** Update stored player state by applying accumulated decay
- **Who uses it:** Tournament contract (called internally before any player action)
- **Returns:** Nothing (modifies storage)
- **How it works:** Calculates decay since last update, reduces player's stored coins, updates decay timestamp checkpoint

### Events

-`DecayApplied(address indexed player, uint256 decayAmount, uint256 remainingCoins)`

- **Emitted when:** Decay is applied to a player during any state-changing action
- **Purpose:** Track economic state changes, enable UI updates, provide audit trail
- **Parameters**:
  - `player`: Address of the affected player
  - `decayAmount`: Total coins lost since last decay application
  - `remainingCoins`: Player's coin balance after decay

## Integration with tournament lifecycle

The economic mechanics are embedded throughout the tournament lifecycle and automatically enforce the resource constraints and exit requirements.

### Player resource initialization (triggered when joining a tournament)

When a player joins a tournament, their "economic state" is initialized based on their stake amount and the conversion rate defined in the tournament parameters. Their initial coins amount (in-game currency, no existence/value outside of this tournament instance) are calculated using the coin conversion rate.
The "decay clock" starts immediately at join time and is the baseline for all future decay calculations.

### Automatic decay application (on any action)

Before any state-changing player action (exit, forfeit, fight, trade etc), the system applies accumulated decay. This ensures that the player state is always accurate when making decisions. The decay application updates both the player's coin balance and their decay timestamp checkpoint.

### Exit validation (on exit attempt)

The exit validation checks all requirements including the economic constraints. The system compares the player's current in-game currency amount (AFTER decay) against the current exit cost (AFTER calculations). Both decay and exit cost are calculated in real-time as to ensure accurate validation.

### Tournament conclusion (on end)

When a tournament ends, only the players that successfully exited are eligible to claim a share of the pool prize. Players who did not exit forfeit their entire stake, regardless of their coin balance or other resources. The economic mechanics do not need to calculate final states for all players: **only winners' exit times matter for prize distribution**.

## Calculations implementation

This section provides the exact formulas and implementation details for all economic calculations in the tournament system.

### Decay

Notes:

- If `totalDecay > storedCoins`, result is clamped to 0 (cannot be negative)
- If `intervalsPassed = 0` (no time passed), no decay is applied
- Partial intervals are ignored: if the decayInterval is 1200 sec, 1199 elapsed seconds will be considered as 0 interval.

**Formula :**

```
intervalsPassed = (currentTimestamp - lastDecayTimestamp) / decayInterval
totalDecay = decayAmount * intervalsPassed
currentCoins = max(0, storedCoins - totalDecay)
```

Example:

```
With:

storedCoins = 400
decayAmount = 10
decayInterval = 1200 seconds (20 minutes)
lastDecayTimestamp = tournament start (0h)
currentTimestamp = 1 hour later (3600 seconds)

We get:
intervalsPassed = (3600 - 0) / 1200 = 3
totalDecay = 10 * 3 = 30 coins
currentCoins = max(0, 400 - 30) = 370 coins
```

### Exit costs

Notes:

- If tournament is not `Active`, exit cost is 0
- If player doesn't exist, exit cost is 0
- Partial intervals are ignored
- Cost can grow beyond initial coins (by design)

```
intervalsPassed = (currentTimestamp - actualStartTime) / exitCostInterval
baseCost = (initialCoins * exitCostBasePercentBPS) / 10000
multiplier = 10000 + (exitCostCompoundRateBPS * intervalsPassed)
exitCost = (baseCost * multiplier) / 10000
```

Example:

```
With:

initialCoins = 400
exitCostBasePercentBPS = 5000 (50%)
exitCostCompoundRateBPS = 1000 (10% per interval)
exitCostInterval = 3600 seconds (1 hour)
actualStartTime = 0
currentTimestamp = 2 hours (7200 seconds)

We get:
intervalsPassed = (7200 - 0) / 3600 = 2
baseCost = (400 * 5000) / 10000 = 200 coins
multiplier = 10000 + (1000 * 2) = 12000
exitCost = (200 * 12000) / 10000 = 240 coins
```

---

## Enhancements

Those are some features that would be cool to implement for game designers, but that (probably) won't be during the hackathon because of the time constraints :

- Alternative growth curves: this would game designers to choose different exit cost curves (eg: Exponential, Linear, Sin, Step based)

Examples of such patterns:

1. Linear growth base (`base + (rate * intervals)`)

```
Start: 200 coins
At Hour 1: 210 coins (+10)
At Hour 2: 220 coins (+10)
At Hour 3: 230 coins (+10)
```

2. Exponential growth

```
Start: 200 coins
At Hour 1: 220 coins (+10%)
At Hour 2: 242 coins (+10% of 220)
At Hour 3: 266 coins (+10% of 242)
```

3. Phase-based custom growth

```
Start: 200 coins (base)
Hour 1: 210 coins (+5%)
Hour 2: 208 coins (-1%)
Hour 3: 218 coins (+5%)
Hour 4: 216 coins (-1%)
```
