# Combat system

## User stories breakdown

### Combat initiation

**As a player**,
I want to **challenge another player to a rock-paper-scissors match**,
So that I can **gain lives by winning or lose lives by losing**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player
  AND I have at least 1 card of any type
  AND target player has at least 1 card of any type
WHEN I initiate a fight with another player
THEN both players select their cards offchain (commit phase)
  AND the backend resolves the match
  AND the result is posted onchain
  AND `FightInitiated(player1, player2, timestamp)` event is emitted
```

**As a player**,
I want to **be matched with a random opponent**,
So that I can **participate in combat even if I don't have a specific target**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player
  AND I have at least 1 card of any type
WHEN I request a random match
THEN the backend matches me with an available opponent
  AND combat proceeds as normal
  AND `RandomMatchMade(player1, player2, timestamp)` event is emitted
```

### Card selection and commit-reveal

**As the game system**,
I want to **handle card selection offchain using commit-reveal**,
So that **neither player can cheat by seeing their opponent's choice**.

```
GIVEN both players have been matched for combat
WHEN players select their cards
THEN each player commits their choice hash offchain to the backend
  AND once both commitments are received, players reveal their choices
  AND backend validates that revealed choices match commitments
  AND if validation fails, the cheating player automatically loses
  AND `CardCommitted(player, commitHash)` event is emitted (backend internal)
```

### Combat resolution (basic)

**As the game system**,
I want to **resolve combat results and update player states**,
So that **winners gain lives and losers lose lives**.

```
GIVEN both players have revealed their valid card choices
WHEN the backend resolves the match
THEN rock-paper-scissors rules apply:
  - Rock beats Scissors
  - Scissors beats Paper
  - Paper beats Rock
  - Same card = Draw (no life change, both cards still consumed)
THEN the winner gains +1 life
  AND the loser loses -1 life
  AND both players' selected cards are destroyed (consumed)
  AND the backend posts the result onchain via combat referee address
  AND `FightResolved(player1, player2, winner, player1Card, player2Card)` event is emitted
```

### Modifier application during combat

**As the game system**,
I want to **check for and apply active modifiers during combat**,
So that **mystery card effects can influence fight outcomes**.

```
GIVEN a fight has been initiated
  AND one or both players have an active modifier (currentModifier.exists = true)
WHEN the backend resolves the match
THEN modifiers are applied in this order:
  1. `OnNextFight` modifiers (before base result)
  2. Base fight result (rock-paper-scissors outcome)
  3. `OnNextWin` modifiers (for winner only)
  4. `OnNextLoss` modifiers (for loser only)
THEN all triggered modifiers are cleared (currentModifier.exists = false)
  AND `ModifierApplied(player, cardId, effect)` event is emitted for each modifier
  AND final combat result is posted onchain
  AND `FightResolved` event includes modifier effects applied
```

### Card consumption validation

**As the game system**,
I want to **ensure players have sufficient cards to participate in combat**,
So that **the game state remains consistent and players can't fight without resources**.

```
GIVEN a player attempts to initiate or accept a fight
WHEN validating combat eligibility
THEN player must have totalCards >= 1
  AND player must have at least 1 card of the type they wish to play
  AND if validation fails, combat is rejected
  AND `CombatRejected(player, reason)` event is emitted
```

### Post-combat state update

**As the game system**,
I want to **update player resources onchain after combat resolution**,
So that **all state changes are verifiable and permanent**.

```
GIVEN the backend has resolved a fight with all modifiers applied
WHEN the combat referee posts results onchain
THEN the following state updates occur:
  - Player lives adjusted (winner +1, loser -1, or modified by effects)
  - Both players' totalCards reduced by 1
  - Specific card types (rock/paper/scissors) reduced for each player
  - All triggered modifiers removed from activeModifier mapping
  - hasActiveModifier flags updated if no modifiers remain
  - isFighting flags set to false for both players
THEN `FightResolved` event contains complete before/after state
  AND transaction reverts if player state is inconsistent
```

### Cheater detection and flagging

**As the game system**,
I want to **automatically flag players who provide invalid commitment reveals**,
So that **other players can make informed decisions about engaging with them**.

```
GIVEN a player's reveal does not match their commitment
WHEN the backend detects the mismatch during fight resolution
THEN the cheating player automatically loses the fight
  AND the player's status is changed to "Flagged"
  AND the player can continue playing but is marked publicly
  AND other players can see the flag and choose to avoid trading/fighting
  AND `PlayerFlagged(player, reason, timestamp)` event is emitted
```

### Combat state protection

**As the game system**,
I want to **prevent players from exiting or forfeiting while in active combat**,
So that **combat results are always properly resolved**.

```
GIVEN a player is in an active fight (isFighting = true)
WHEN the player attempts to exit or forfeit
THEN the transaction reverts with "Currently in combat"
  AND the player must wait for combat resolution
  AND the isFighting flag is automatically cleared when combat resolves
```

### Draw handling

**As the game system**,
I want to **handle draw scenarios fairly**,
So that **players don't exploit draws to preserve lives**.

```
GIVEN both players selected the same card type
WHEN resolving the fight
THEN no lives are gained or lost by either player
  AND both cards are still consumed (destroyed)
  AND modifiers still apply according to their triggers
  AND `FightResolved` event indicates draw result
```

## Technical breakdown

The combat system operates on a **hybrid trust model**: card selection and initial resolution happen offchain (backend) to enable commit-reveal mechanics and minimize cheating (games can never 100% eliminate cheating), while final results and state changes are posted onchain for verifiability and integration with other systems (internal and externals, including community-made systems, eg people could create their own server !).

### Offchain coordination (Backend - [Rivet actors](https://www.rivet.dev/docs/actors/))

The backend manages the **interactive phase** of combat:

1. **Matchmaking**: Pairs players either by direct challenge or random matching
2. **Commit-Reveal**: Collects card choice commitments from both players, then reveals
3. **Validation**: Ensures revealed choices match commitments (anti-cheat)
4. **Resolution**: Applies rock-paper-scissors rules, checks for and applies modifiers
5. **Posting**: Sends final result to smart contract via authorized combat referee address

This approach should minimize and help prevent:

- **Cheating** No one can see opponent's choice before committing their own
- **State manipulation**: Only the trusted referee wallet can post results onchain

### Onchain state management (contracts)

The smart contract manages **permanent state**:

1. **Authorization**: Only the combat referee wallet can post fight results
2. **State updates**: Lives, cards, and modifiers are updated atomically
3. **Event emission**: combat results, state changes are logged
4. **Validation**: Ensures players exist, are active, have the requiredresources, and state is consistent
5. **Modifier management**: Removes triggered modifiers, updates flags

The contract **DOES NOT**:

- Handle card selection UI
- Perform rock-paper-scissors logic (trusts referee)
- Manage commitments (offchain only)

### Modifier resolution flow

When a fight occurs with active modifiers:

**Modifier application rules**:

- **One modifier per trigger type**: A player can only have one modifier for each trigger (`OnNextFight`, `OnNextWin`, `OnNextLoss`)
- **Defensive priority**: Defensive modifiers (shields, blocks) take precedence over offensive modifiers (@todo - could be configurable ? )
- **Strict order**: Modifiers apply in a fixed sequence to prevent ambiguity
- **Auto-removal**: All triggered modifiers are removed **immediately** after resolution

**Pre-fight (OnNextFight modifiers)**:

- Applied **before determining winner/loser**
  eg: "Shield" - Prevents life loss this fight
  eg: "Reversal" - Swap winner and loser

**Post-fight (OnNextWin/OnNextLoss modifiers)**:

- Applied **after base result is determined**
  eg: "Life Steal" - Winner takes 2 lives instead of 1
  eg: "Insurance" - Loser doesn't lose a life

**Draw scenario**:

- `OnNextFight` modifiers still apply (may prevent or cause draw)
- `OnNextWin`/`OnNextLoss` modifiers do NOT apply (no winner/loser)
- Cards still get consumed

**Resolution order**:

```
1. Check and apply OnNextFight modifiers (both players)
   ↓ (may change who wins/loses)
2. Determine final fight result (Rock-Paper-Scissors + modifiers)
   ↓
3. Identify winner and loser based on final result
   ↓
4. Apply OnNextWin modifiers (to winner only)
   ↓
5. Apply OnNextLoss modifiers (to loser only)
   ↓
6. Calculate final life/coin changes
   ↓
7. Remove all triggered modifiers
   ↓
8. Reset isFighting flags
```

### Edge cases and resolution rules

#### Multiple modifiers of same trigger

**Situation**: What if a player somehow has multiple `OnNextFight` modifiers?

**Solution**: **Not possible by design**. The system enforces one modifier per trigger type:

```solidity
struct PlayerResources {
    mapping(ModifierTrigger => ActiveModifier) activeModifier;
    bool hasActiveModifier;
}

// When drawing mystery card that grants modifier
function applyModifierCard(...) internal {
    if (player.activeModifier[trigger].exists) {
        revert ModifierSlotOccupied();
    }
    // Player must resolve current modifier before drawing another
}
```

#### Conflicting modifiers

**Situation**: Player A has "Life Steal" (take 2 lives), Player B has "Shield" (prevent life loss)

**Solution**: **Defensive modifiers always win**:

```solidity
// In modifier resolution
if (loser.hasDefensiveModifier(OnNextFight)) {
    // Block ALL life loss from offensive modifiers
    lifeLossAmount = 0;
    emit ModifierBlocked(attacker, defender, "Shield blocked Life Steal");
} else {
    // Apply offensive modifiers normally
    applyOffensiveModifiers(winner, loser);
}
```

Card design explicitly marks modifiers as defensive/offensive.

#### Modifier changes fight outcome

**Situation**: Player plays losing card but has "Reversal" modifier

**Solution**: Apply modifiers in strict order, recalculate winner:

```solidity
// 1. Determine base RPS result
FightResult baseResult = getRPSResult(player1Card, player2Card);

// 2. Apply OnNextFight modifiers (can change result)
FightResult finalResult = applyPreFightModifiers(baseResult);

// 3. NOW determine winner/loser from FINAL result
address winner = getWinner(finalResult);
address loser = getLoser(finalResult);

// 4. Apply post-fight modifiers to correct winner/loser
if (finalResult != FightResult.Draw) {
    applyModifiers(winner, ModifierTrigger.OnNextWin);
    applyModifiers(loser, ModifierTrigger.OnNextLoss);
}
```

#### Modifier creates negative lives

**Situation**: Player has 1 life, loses fight (-1), has `OnNextLoss` modifier that costs -1 life

**Solution**: Clamp to zero with explicit handling:

```solidity
function applyLifeChange(
    PlayerResources storage player,
    int8 change
) internal {
    int256 newLives = int256(uint256(player.lives)) + int256(change);

    if (newLives < 0) {
        player.lives = 0;  // Can't go negative
        emit PlayerAtZeroLives(player);
    } else if (newLives > 255) {
        player.lives = 255;  // Clamp to uint8 max (unlikely)
    } else {
        player.lives = uint8(uint256(newLives));
    }
}
```

> Note: Players at 0 lives can still play (no elimination), they just can't meet exit requirements.

#### Draw with modifiers

**Situation**: Both players play Rock. Player A has "Double or Nothing" (OnNextWin)

**Solution**: **OnNextWin/OnNextLoss do NOT trigger on draws** (no winner/loser):

```solidity
if (finalResult == FightResult.Draw) {
    // Cards still consumed
    player1.totalCards--;
    player2.totalCards--;

    // OnNextWin/OnNextLoss modifiers do NOT trigger
    // and remain active for next fight

    emit FightResolved(player1, player2, address(0), ...);
}
```

Only `OnNextFight` modifiers can affect draws (eg a modifier that prevents draws).

#### Player disconnects mid-fight

**Situation**: Player commits but never reveals

**Solution**: Backend handles with timeout + auto-loss:

```
Backend timeline:
- T+0s: Both players commit
- T+0s: Request reveals from both
- T+30s: Player A revealed, Player B timed out
- T+30s: Backend posts result: Player B auto-loss + flagged as cheater
- T+30s: Contract receives result, clears both isFighting flags

Player B can immediately play again (just lost life + card + got flagged)
```

Emergency fallback (backend crashed):

```solidity
// If backend never posts result after 5 minutes
function emergencyResetFightingFlag() external {
    require(block.timestamp >= lastFightStartTime + 5 minutes);
    players[msg.sender].isFighting = false;
}
```

> Probably won't implement this during the hackathon unless I have enough time.

#### Flagged player behavior

**Situation**: Can flagged players still play?

**Solution**: **Yes, but with social consequences**:

- Flagged status is permanent for tournament duration
- No automatic penalties (no stake slashing)
- Other players see flag in UI and can refuse to trade/fight (it's up to them)
- Flagged players can still exit if they meet requirements
- Frontend shows warning: "This player was flagged for cheating"

This is a social penalty, not a financial one.

> Could also make interesting observations from analytics: how many players accepted to interact with a cheater after they were flagged ?

### Trust boundaries

**What the backend CAN do**:

- Match players
- Manage commit-reveal process
- Determine which modifiers apply
- Calculate final life/card changes

**What the backend CANNOT cheat on**:

- Player existence (verified onchain)
- Player resources (lives/cards verified onchain)
- Final state changes (posted onchain, validated)
- Modifier definitions (defined in MysteryCardRegistry)

**What players must trust**:

- Backend correctly implements rock-paper-scissors rules
- Backend applies modifiers according to their definitions
- Backend doesn't reveal commitments early
- Backend matches players fairly

> Players must already trust that their server-authorative game is fair, so it's not a stretch.

## System requirements

### `TournamentCore.sol`

```solidity
struct Params {
    address combatReferee;  // Authorized backend address for posting combat results
}

enum CardType {
    ROCK,
    PAPER,
    SCISSORS
}

enum FightResult {
    Player1Wins,
    Player2Wins,
    Draw
}

struct CombatResult {
    address player1;
    address player2;
    CardType player1Card;
    CardType player2Card;
    FightResult result;
    ModifierEffect[] modifiersApplied;
    bool cheaterDetected;
    address cheater;
    uint32 timestamp;
}

struct ModifierEffect {
    address player;
    uint8 cardId;
    int8 livesAdjustment;  // Can be positive or negative
    uint256 coinsAdjustment;
    string effectDescription;
}
```

### `TournamentCombat`

**Goal**: Handle combat resolution, modifier application, and state updates

**Who uses it**: Tournament contract, called by combat referee

**How it's used**:

- Combat referee (backend) calls `resolveFight` with combat result
- Library validates players exist and have resources
- Applies modifiers in correct order
- Updates player lives and card counts atomically
- Emits events for all state changes

**Events**:

```solidity
event FightInitiated(
    address indexed player1,
    address indexed player2,
    uint256 timestamp
);

event FightResolved(
    address indexed player1,
    address indexed player2,
    address indexed winner,  // address(0) for draw
    CardType player1Card,
    CardType player2Card,
    ModifierEffect[] modifiersApplied,
    uint32 timestamp
);

event ModifierApplied(
    address indexed player,
    uint8 cardId,
    ModifierTrigger trigger,
    bytes effectData
);

event CombatRejected(
    address indexed player,
    string reason
);

event PlayerFlagged(
    address indexed player,
    string reason,
    uint256 timestamp
);
```

**Key functions**:

```solidity
function resolveFight(
    mapping(address => PlayerResources) storage players,
    CombatResult calldata result
) internal;

function applyModifiers(
    PlayerResources storage player,
    ModifierTrigger trigger,
    FightResult context
) internal;

function clearResolvedModifiers(
    PlayerResources storage player,
    ModifierTrigger trigger
) internal;

function validateCombatEligibility(
    PlayerResources storage player,
    CardType cardToPlay
) internal view returns (bool);

function applyLifeChange(
    PlayerResources storage player,
    int8 change
) internal;

function flagPlayer(
    PlayerResources storage player,
    address playerAddress,
    string calldata reason
) internal;
```

### `Tournament.sol`

Referee validation modifier:

```solidity
modifier onlyReferee() {
    if (msg.sender != params.combatReferee) revert OnlyReferee();
    _;
}

modifier notInCombat() {
    if (players[msg.sender].isFighting) revert InCombat();
    _;
}

modifier notFlagged() {
    if (players[msg.sender].status == PlayerStatus.Flagged) {
        revert Flagged();
    }
    _;
}
```

Combat resolution functions:

```solidity
function resolveFight(
    TournamentCore.CombatResult calldata result
) external
  onlyReferee
  applyDecayFirst  // Apply to both players
  autoEndIfTimeUp
  onlyStatus(TournamentCore.Status.Active)
{
    // Set fighting flags
    // Handle cheater detection
    // Resolve fight
    // Clear fighting flags
    _checkEarlyEnd();
}

// Emergency reset (only if backend fails to post result after X minutes)
function emergencyResetFightingFlag() external onlyPlayer { }
```

Update exit and forfeit functions:

```solidity
function exit() external
  onlyPlayer
  notInCombat  // NEW
  notFlagged   // NEW (optional - allow flagged to exit?)
  applyDecayFirst
  autoEndIfTimeUp
  onlyStatus(TournamentCore.Status.Active)
{}

function forfeit() external
  onlyPlayer
  notInCombat  // NEW
  applyDecayFirst
  autoEndIfTimeUp
  onlyStatus(TournamentCore.Status.Active)
{}
```

### `PlayerResources` struct updates

```solidity
struct PlayerResources {
    // ... existing fields
    uint8 rockCards;
    uint8 paperCards;
    uint8 scissorsCards;

    // Keep totalCards for exit condition and public info
    uint8 totalCards;  // Must equal rockCards + paperCards + scissorsCards

    bool isFighting;  //  Prevents exit/forfeit during active combat
    uint256 lastFightStartTime;  //  Timestamp when fight started (for emergency reset)

    // Modifier state (one active modifier at a time per trigger type)
    mapping(ModifierTrigger => ActiveModifier) activeModifier;
    bool hasActiveModifier;  // Quick check if ANY modifier is active
}
```

### Backend (Rivet actors) responsibilities

**Matchmaking service**:

- Maintains pool of players seeking matches
- Handles direct challenges
- Creates random pairings

**Commit-Reveal coordinator**:

- Collects commitment hashes from both players
- Stores commitments with timeout (30 seconds)
- Requests reveals once both committed
- Validates reveals match commitments
- Penalizes players who don't reveal (auto-loss)

**Combat resolver**:

- Applies rock-paper-scissors logic
- Queries player modifier state from contract
- Applies modifiers in correct order
- Constructs `CombatResult` with all effects
- Signs and posts result to contract via referee address

**State synchronization**:

- Listens to `FightResolved` events
- Updates internal game state
- Notifies player clients of results
- Handles disconnections and timeouts

### Security considerations

**Referee wallet management**:

- Private key stored securely in backend environment (maybe use Thirdweb Server Wallet service?)
- Separate from admin/creator keys
- Can be rotated if compromised (requires new tournament)

**Commitment validation**:

- Timeout mechanism (N seconds to reveal)
- No-show = automatic loss
- Invalid reveal = automatic loss
- Prevents griefing by non-revealing

**Modifier exploit prevention**:

- Modifiers removed immediately after triggering
- Can't stack multiple of same modifier (unless explicitly allowed)
- Modifier effects capped (eg can't steal more lives than opponent has)

**Cheating minimization**:

- Commit-reveal should seeing opponent choice

### Flow

```
Player A initiates fight with Player B
 THEN
Backend creates match, requests commitments
 THEN
Player A commits hash(ROCK + secret)
Player B commits hash(PAPER + secret)
 THEN
Both commitments received, backend requests reveals
 THEN
Player A reveals: ROCK + secret
Player B reveals: PAPER + secret
 THEN
Backend validates reveals match commitments
 THEN
Backend checks player modifiers onchain
 THEN
Backend resolves:
  - Check OnNextFight modifiers
  - Apply base RPS rules (Paper wins)
  - Check OnNextWin/OnNextLoss modifiers
  - Calculate final life changes
  - Mark cards as consumed
 THEN
Backend posts CombatResult to Tournament contract
 THEN
Contract validates referee address
Contract updates player states atomically:
  - Player A: lives -1, paperCards -1, totalCards -1
  - Player B: lives +1, rockCards -1, totalCards -1
  - Remove triggered modifiers
 THEN
Contract emits FightResolved event
 THEN
Backend notifies players of result
Players see updated states in UI
```

**Tests**
_Smart contracts:_

- Full combat flow with multiple fights
- Modifier chains (multiple modifiers on one player)
- Card depletion (fight until 0 cards)
- Concurrent fights (multiple pairs fighting simultaneously)
- Tournament end via combat (all players deplete cards)

_Server_

- Commit-reveal flow
- Timeout handling
- Invalid commitment rejection
- Matchmaking logic
- State synchronization after fight
