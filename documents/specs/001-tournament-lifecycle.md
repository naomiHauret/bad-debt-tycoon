@doing

# Tournament lifecycle

## User stories breakdown

### Tournament design & creation

As a game designer
I want to be able to define these as the immutable, verifiable rules of a tournament :

- a minimum amount of players
- a maximum amount of players (optional)
- a start time
- a duration (minimum 20 minutes)
- a minimum stake (optional)
- a maximum stake (optional)
- a stablecoin to put at stake (PYUSD, USDC, GHO)
- Condition(s) for the contest start to start :
  - Amount of players
  - Amount currently at stake in the pool
  - Timestamp
- Decay base rate
- Base exit condition(s) for the players
  - In-game currency amount
  - Lives amounts
- Exit penalty
- (nice to have) which cards will be available in the mystery deck
- (nice to have) decay variance law (eg: uniform, exponential...)

So that...

- players can decide whether or not to join a tournament based on its rules
- users can create their own tournaments

```
GIVEN I am creating a tournament
WHEN I provide parameters
THEN `minPlayers` must be >= 2
  AND `maxPlayers` must be 0 or >= `minPlayers`
  AND `duration` must be >= 1200 seconds (20 minutes)
  AND `stakeToken` must be a valid whitelisted ERC20 address
  AND if `maxStake` > 0, then `maxStake` >= minStake
  AND at least one start condition must be enabled
  AND `decayBaseRate` must be > 0
  AND `exitPenaltyPercent` must be <= 100

GIVEN I am a user with sufficient funds
WHEN I call `createTournament()` with valid parameters
THEN a new `Tournament` contract is deployed
  AND the tournament is registered in `TournamentRegistry`
  AND the creator is set as tournament owner
  AND all parameters are stored immutably
  AND a `TournamentCreated` event is emitted
```

### Discovery

As a player,
I want to browse available tournaments and view their rules,
So that I can choose which tournament to join based on my preferences.

### Entry

As a player,
I want to join a tournament by staking the required amount,
So that I can participate in the game.

```
GIVEN a tournament is in "Open" `status`
  AND I have approved sufficient `stakeToken`
WHEN I call `joinTournament(stakeAmount)`
THEN stakeAmount must be within min/max stake bounds
  AND `stakeToken` is transferred from me to tournament contract
  AND I am added to players list
  AND my initial resources are allocated (stars, coins, cards)
  AND `PlayerJoined` event is emitted
  AND if start conditions are met, tournament auto-starts, `TournamentStarted` event is emitted
```

### Tournament lifecycle automation

As a game designer,
I want to automatically or manually start and end a tournament when conditions are met,
So that the game can begin at the appropriate moment with optimal playing conditions and end when planned.

```
GIVEN a tournament is in "Open" `status`
WHEN a start condition is met:
  - Player count reaches `startPlayerCount`
  OR total staked reaches `startPoolAmount`
  OR block.timestamp >= startTimestamp
THEN tournament status changes to "Active"
  AND `startTime` is recorded
  AND `endTime` is calculated (`startTime` + duration)
  AND secret objectives are assigned
  AND `TournamentStarted` event is emitted
```

```
GIVEN a tournament is in "Active" status
WHEN block.timestamp >= `endTime`
THEN tournament status changes to "Ended"
  AND winners are identified
  AND prize pool is calculated
  AND `TournamentEnded` event is emitted
```

```
GIVEN a tournament is in "Open" status
  AND block.timestamp > startTimestamp
  AND start conditions are NOT met (insufficient players/pool)
THEN tournament status changes to "Cancelled"
  AND all players can claim their stakes back
  AND TournamentCancelled event is emitted
```

### Prize distribution

I want to manually claim my prize after the tournament ends,
So that I receive my share of the prize pool.

```
GIVEN a tournament has ended with W winners
WHEN calculating prize shares
THEN totalPrizePool = totalStaked
  AND platformFee = totalPrizePool * platformFeePercent / 100
  AND creatorFee = totalPrizePool * creatorFeePercent / 100
  AND remainingPool = totalPrizePool - platformFee - creatorFee
  AND each winner receives: remainingPool / W
```

```
GIVEN a tournament is in "Completed" status
  AND I am a winner (successfully exited)
WHEN I call claimPrize()
THEN my share of remaining pool is calculated
  AND `stakeToken` is transferred to me
  AND I am marked as `claimed`
  AND `PrizeClaimed` event is emitted
```

---

(future)
As a game designer,
I want to end the tournament when duration expires or all conditions are met,
So that winners can be determined and prizes distributed.

```
GIVEN a tournament is in "Completed" status
WHEN `claimPrize()` is called
THEN fees are calculated and deducted (eg: 1% platform fee, 0.25% creator fee)
  AND remaining pool is split among winners
  AND `stakeToken` is transferred to each winner
  AND `PrizesDistributed` event is emitted
```

### Reinbursment

As a player in a cancelled tournament,
I want to claim my stake back if start conditions aren't met,
So that my funds aren't locked indefinitely.

```
GIVEN a tournament is in "Cancelled" status
  AND I joined the tournament
WHEN I call claimRefund()
THEN my full stake is returned to me
  AND I am marked as `refunded`
  AND `StakeRefunded` event is emitted
```

## Technical breakdown

The Tournament Management feature is a permissionless system that allows creators to **define, deploy, and manage game instances with customizable rules**.
Each tournament is an **isolated game with its own parameters, prize pool, and player set**.
Tournaments can run concurrently.

### System requirements

- `TournamentFactory.sol`: Deploys new tournament contracts
- `Tournament.sol`: Main game contract with configurable rules
- `TournamentRegistry.sol`: Tracks all active/completed tournaments
- `TournamentParameters.sol`: Immutable configuration struct
