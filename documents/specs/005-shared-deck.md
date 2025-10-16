# Mystery shared cards deck

## User stories breakdown

### Deck initialization

**As the game system**,
I want to **create a shared deck of mystery effect cards at tournament start**,
So that **players can interact with it throughout the game**.

```
GIVEN a tournament is being created
  AND the creator has specified excluded cards (optional)
WHEN the tournament starts (status changes to "Active")
THEN a shared mystery deck is initialized with cards from MysteryCardCatalog
  AND excluded cards are removed from the deck
  AND the deck is shuffled using a verifiable random seed
  AND `DeckInitialized(tournamentAddress, deckSize, seedCommitment)` event is emitted
```

**As the game system**,
I want to **shuffle the shared deck content using verifiable randomness**,
So that **players can't predict the order of cards and can verify fairness later**.

```
GIVEN a tournament deck is being initialized or shuffled
WHEN the shuffle operation occurs
THEN a random seed is generated (using Pyth Entropy)
  AND the seed is combined with backend secret to create final shuffle seed
  AND the deck order is determined deterministically from the seed
  AND the seed commitment is stored onchain (full seed revealed at tournament end)
  AND `DeckShuffled(seedCommitment, timestamp)` event is emitted
```

### Card categories

**As the game system**,
I want to **support three distinct types of mystery cards**,
So that **cards can have immediate, delayed, or resource-adding effects**.

**Card effects**:

1. **Instant cards**: Resolve immediately upon drawing (coins adjustment, immediate life change, forced action)
2. **Modifier cards**: Create pending effects that trigger on specific conditions (OnNextFight, OnNextWin, OnNextLoss, OnDraw, OnTrade)
3. **Resource cards**: Add a Rock, Paper, or Scissors card to the player's hand

```
GIVEN a player draws a card from the mystery deck
WHEN the backend determines the card type
THEN based on the card category:
  - Instant: Effect applied immediately, no pending state
  - Modifier: Effect stored in activeModifier mapping, triggers later
  - Resource: Card added to player's hand (specific type hidden from others)
```

### Drawing mechanism

**As a registered player with enough coins and no active modifier**,
I want to **draw a card from the shared deck**,
So that **I can gain advantages or resources unpredictably**.

```
GIVEN a tournament is in "Active" status
  AND I am an "Active player with sufficient coins
  AND the deck has cards remaining
  AND I do NOT have any active modifier (currentModifier.exists = false)
WHEN I pay the draw cost and request to draw
THEN coins are deducted from my balance
  AND deck draw count increments
  AND `CardDrawn(player, drawIndex, costPaid)` event is emitted
  AND backend determines which card was drawn using (seed + drawIndex)
  AND backend applies the card effect based on its category
```

**As the game system**,
I want to **enforce that players can only draw one card at a time**,
So that **modifier effects resolve completely before new cards are drawn**.

```
GIVEN a player has an active modifier card (hasActiveModifier = true)
WHEN the player attempts to draw another card
THEN the transaction reverts with "Must resolve active modifier first"
  AND the player must wait for their modifier to trigger and resolve
  AND once resolved, hasActiveModifier becomes false and drawing is allowed again
```

**As the game system**,
I want to **prevent drawing from an empty deck**,
So that **the game state doesn't have an existential crisis**.

```
GIVEN the mystery deck has 0 cards remaining
WHEN a player attempts to draw
THEN the transaction reverts with "Deck empty"
```

### Card effects application

**As the game system**,
I want to **apply instant card effects immediately**,
So that **players see immediate results from their draw**.

```
GIVEN a player drew an instant effect card
WHEN the backend processes the draw
THEN the effect is calculated and applied immediately
  AND player state is updated (coins, lives, etc.)
  AND the card is consumed (removed from deck)
  AND `InstantCardResolved(player, cardId, effectData)` event is emitted
  AND hasActiveModifier remains false (no pending state)
```

**As the game system**,
I want to **store modifier card effects until their trigger condition is met**,
So that **players can't stacked cards and are forced to take actions**.

```
GIVEN a player drew a modifier card
WHEN the backend processes the draw
THEN the modifier is stored in activeModifier[trigger] mapping
  AND hasActiveModifier is set to true
  AND the card is consumed (removed from deck)
  AND `ModifierCardApplied(player, cardId, trigger)` event is emitted
  AND the player cannot draw another card until this modifier resolves
```

**As the game system**,
I want to **add resource cards directly to the player's hand**,
So that **players can gain additional combat cards from the mystery deck**.

```
GIVEN a player drew a resource card (Rock, Paper, or Scissors)
WHEN the backend processes the draw
THEN the specific card type is added to player's hand:
  - totalCards increases by 1
  - rockCards/paperCards/scissorsCards increases by 1 (specific type)
  AND the card is consumed (removed from deck)
  AND `ResourceCardAdded(player, cardId, timestamp)` event is emitted
  AND card type is NOT revealed publicly (information hiding)
  AND hasActiveModifier remains false
```

### Modifier resolution

**As the game system**,
I want to **automatically resolve modifier cards when their trigger occurs**,
So that **card effects apply at the right moment without manual intervention**.

```
GIVEN a player has an active modifier
  AND the trigger condition occurs (e.g., player enters a fight, wins, loses, draws another card, accepts a trade)
WHEN the triggering action is processed
THEN the modifier effect is applied according to the card definition
  AND the modifier is removed from activeModifier mapping
  AND hasActiveModifier is set to false (if no other modifiers remain)
  AND `ModifierResolved(player, cardId, trigger, effectApplied)` event is emitted
  AND the player can now draw new mystery cards again
```

### Deck manipulation cards

#### Shuffle

**As a registered player with enough coins**,
I want to **pay to shuffle the remaining mystery deck**,
So that **the order of future draws becomes unpredictable again**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player with enough coins
  AND the deck has cards remaining
WHEN I pay the shuffle cost
THEN coins are deducted from my balance
  AND a new random seed is requested from Pyth Entropy
  AND the backend generates a new shuffle with (new seed + backend secret)
  AND remaining deck is reordered based on new seed
  AND `DeckShuffled(player, newSeedCommitment, timestamp)` event is emitted
```

#### Peek

**As a registered player with enough coins**,
I want to **pay to see the next N cards in the deck without drawing them**,
So that **I can make informed decisions about whether to draw**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player with sufficient coins
  AND the deck has at least N cards remaining
WHEN I pay the peek cost
THEN coins are deducted from my balance
  AND backend reveals next N cards to me privately (not onchain)
  AND deck order remains unchanged
  AND `DeckPeeked(player, cardCount, costPaid)` event is emitted (amount only, not cards)
```

#### Add cards

**As a registered player with enough coins**,
I want to **pay to add specific cards to the deck at chosen positions**,
So that **I can manipulate future draws strategically**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player with sufficient coins
  AND I specify valid card positions
WHEN I pay the manipulation cost
THEN coins are deducted from my balance
  AND specified cards are inserted at chosen deck positions
  AND deck size increases
  AND `CardsAddedToDeck(player, cardIds, positions, costPaid)` event is emitted
```

#### Remove cards

**As a registered player with enough coins**,
I want to **pay to remove specific cards from the deck**,
So that **I can eliminate unfavorable cards**.

```
GIVEN a tournament is in "Active" status
  AND I am an active player with sufficient coins
  AND I specify valid positions in the deck
WHEN I pay the manipulation cost
THEN coins are deducted from my balance
  AND cards at specified positions are removed
  AND deck size decreases
  AND `CardsRemovedFromDeck(player, positions, costPaid)` event is emitted
```

## Technical breakdown

The mystery shared cards deck operates as a **hybrid system** combining onchain state management with offchain deterministic randomness:

### Public system (contracts)

The onchain component defines **rules and economics**:

1. **Card definitions**: Global catalog of all possible mystery cards (`MysteryCardCatalog`)
2. **Deck state**: Current size, draw count, (partial) seed (stored in `Tournament`)
3. **Draw costs**: How much players pay to interact with the deck
4. **Access control**: Only players with no active modifiers can draw
5. **Event logging**: All draws, shuffles, and effects are recorded onchain

The contract **does not**:

- Store the actual deck order (too expensive)
- Determine which card is drawn (handled by backend)
- Know the full seed until tournament end (only commitment is stored)

### Private system (Backend - Rivet actor)

The offchain component handles **deterministic execution**:

1. **Deck initialization**: Creates ordered card list based on registry + exclusions
2. **Randomness**: Uses Pyth Entropy seed + backend secret + for verifiable shuffle
3. **Card selection**: Determines card at position (seed + drawIndex) % deckSize
4. **Effect application**: Calculates effect data and posts to contract
5. **State tracking**: Maintains current deck order, remaining cards, player modifiers

### Deterministic randomness & verifiability

The system uses **commit-reveal** with verifiable randomness:

**During tournament**:

- Initial seed: `Pyth VRF output + backend secret` to get the shuffle seed
- Draw N: `PRNG(shuffle seed, drawIndex)` determines card at position
- Only seed _commitment_ is stored onchain (hash of full seed)

**After tournament**:

- Backend publishes full seed (Pyth output + backend secret)
- Anyone can reconstruct entire deck order based on that

### Card category system

**Instant cards** (immediate resolution):
eg: "Windfall" (+50 coins), "Tax" (-30 coins), "First Aid" (+1 life)

- Applied immediately when drawn
- No pending state created
- Player can draw again immediately

**Modifier cards** (pending effects):
eg: "Shield" (OnNextFight: prevent life loss), "Life Steal" (OnNextWin: take 2 lives)

- Stored in `activeModifier[trigger]` mapping
- **Only one modifier per trigger type** at a time
- Blocks further card draws until resolved
- Automatically applied when trigger occurs
- Removed after triggering

**Resource cards** (add combat cards):

- Examples: "Rock" (adds rock card), "Paper" (adds paper card), "Scissors" (adds scissors card)
- Increases player's hand size
- Specific type hidden from other players
- Player can draw again immediately

### One-card-at-a-time rule

**Core constraint**: A player can only have **one active mystery card effect** at a time.

This to :

- Avoids complex modifier stacking logic
- Force players to choose when to draw (timing matters!)
- Make things easier on the smart contract side

**Edge cases**:

- Instant card drawn while having modifier: Not possible (draw blocked)
- Modifier triggers during combat: auto-resolves, flag cleared
- Player exits with active modifier: allowed (doesn't block exit)
- Tournament ends with active modifier: modifier lost (doesn't matter)

### Information hiding

**Public information** (anyone can see):

- Player has drawn a card (via event)
- Deck size decreased by 1
- Player paid X coins for draw
- Whether player has an active modifier (bool flag)

**Hidden information**:

- Which specific card was drawn (until effect applies)
- Which specific modifier is active (until it triggers)
- Order of remaining cards in deck
- Full shuffle seed (until tournament ends)

## System requirements

### `MysteryCardCatalog.sol`

**Goal**: Global catalog/registry of all possible mystery cards with their definitions

**Who uses it**:

- Platform admin (adds/removes/updates card definitions)
- `Tournament` contracts (query card definitions)
- Backend (determines card effects)

**How it's used**:

- Admin registers new cards with category, cost, effects
- Admin can enable/disable specific cards globally
- Tournament creators can exclude specific cards per tournament (easier than specify which cards to include) (@todo - maybe we should limit what cards can be in the deck in tournament creation )
- Backend queries card data when actor is spawned, then refers to these definition in its inner state when processing draws

**State**:

```solidity
struct CardDefinition {
    uint8 cardId;
    string name;
    CardCategory category;  // Instant, Modifier, Resource
    uint256 baseCost; // Base draw cost (can be modified per tournament)
    bool enabled; // Global enable/disable

    // For modifier cards
    ModifierTrigger trigger;
    bytes defaultEffectData;  // Encoded effect parameters

    // For resource cards
    CardType cardType;  // ROCK, PAPER, SCISSORS (only for Resource category)
}

enum CardCategory {
    Instant,
    Modifier,
    Resource
}

enum ModifierTrigger {
    None, // For Instant/Resource cards
    OnNextFight,
    OnNextWin,
    OnNextLoss,
    OnDeckDraw,
    OnTrade
}

mapping(uint8 => CardDefinition) public cards;
uint8 public cardCount;
```

**Events**:

```solidity
event CardRegistered(uint8 indexed cardId, string name, CardCategory category);
event CardUpdated(uint8 indexed cardId, string name);
event CardToggled(uint8 indexed cardId, bool enabled);
```

**Key functions**:

```solidity
function registerCard(CardDefinition calldata card) external onlyOwner;
function updateCard(uint8 cardId, CardDefinition calldata card) external onlyOwner;
function toggleCard(uint8 cardId, bool enabled) external onlyOwner;
function getCard(uint8 cardId) external view returns (CardDefinition memory);
function getEnabledCards() external view returns (CardDefinition[] memory); // @todo -might not be necessary
```

### `TournamentCore.sol`

```solidity
struct Params {
    // ... existing params
    uint8[] excludedCardIds; // Cards excluded from this tournament's deck
    uint256 mysteryDeckDrawCost; // Cost to draw a card
    address mysteryDeckOracle; // Backend address authorized to resolve card draws
}

struct DeckState {
    uint8 cardsRemaining;
    uint256 pythVRFOutput;  // Public: Pyth Entropy output (the actual seed is a composite )
    uint256 drawCount; // Total draws from deck
    mapping(address => uint256) playerDrawCount;
}

struct ActiveModifier {
    uint8 cardId;
    ModifierTrigger trigger;
    bytes effectData;
    uint32 appliedAt;
    bool exists;  // For checking if slot is occupied
}

function revealSecret(bytes32 backendSecret) external onlyOracle { }
```

### `TournamentMysteryDeck.sol`

**Goal**: Handle mystery deck interactions, card drawing, and effect application

**Who uses it**: `Tournament` contract, called by backend

**How it's used**:

- Players pay to draw cards, backend determines and applies effects
- Backend posts card effects to contract
- Players pay to shuffle deck
- Deck state tracked onchain, order tracked offchain

**Events**:

```solidity
event DeckInitialized(
    address indexed tournament,
    uint8 deckSize,
    uint256 seed, // this is only part of the seed
    uint32 timestamp
);

event CardDrawn(
    address indexed player,
    uint256 drawIndex,
    uint256 costPaid,
    uint32 timestamp
);

event InstantCardResolved(
    address indexed player,
    uint8 cardId,
    bytes effectData,
    uint32 timestamp
);

event ModifierCardApplied(
    address indexed player,
    uint8 cardId,
    ModifierTrigger trigger,
    bytes effectData,
    uint32 timestamp
);

event ResourceCardAdded(
    address indexed player,
    uint8 cardId,
    uint32 timestamp
);

event ModifierResolved(
    address indexed player,
    uint8 cardId,
    ModifierTrigger trigger,
    bytes effectApplied,
    uint32 timestamp
);

event DeckShuffled(
    address indexed player,
    uint256 newSeed, // this is only part of the seed
    uint32 timestamp
);

event DeckPeeked(
    address indexed player,
    uint8 cardCount,
    uint256 costPaid,
    uint32 timestamp
);
```

**Key functions**:

```solidity
function initializeDeck(
    DeckState storage deck,
    uint256 seed,
    uint8 deckSize
) internal;

function drawCard(
    DeckState storage deck,
    PlayerResources storage player,
    uint256 drawCost
) internal;

function applyInstantCard(
    PlayerResources storage player,
    uint8 cardId,
    bytes calldata effectData
) internal;

function applyModifierCard(
    PlayerResources storage player,
    uint8 cardId,
    ModifierTrigger trigger,
    bytes calldata effectData
) internal;

function applyResourceCard(
    PlayerResources storage player,
    uint8 cardId,
    CardType cardType
) internal;

function resolveModifier(
    PlayerResources storage player,
    ModifierTrigger trigger
) internal returns (bytes memory effectData);

function shuffleDeck(
    DeckState storage deck,
    PlayerResources storage player,
    uint256 newSeedCommitment,
    uint256 shuffleCost
) internal;

function peekDeck(
    DeckState storage deck,
    PlayerResources storage player,
    uint8 cardCount,
    uint256 peekCost
) internal;
```

### `PlayerResources`

```solidity
struct PlayerResources {
    // Mystery deck modifier state
    mapping(ModifierTrigger => ActiveModifier) activeModifier;
    bool hasActiveModifier;  // Flag to know if player can draw
}
```

### `Tournament.sol`

```solidity
modifier onlyDeckOracle() {
    if (msg.sender != params.mysteryDeckOracle) revert OnlyDeckOracle();
    _;
}

modifier canDrawCard() {
    if (players[msg.sender].hasActiveModifier) revert MustResolveModifierFirst();
    _;
}
```

```solidity
TournamentCore.DeckState internal deckState;
```

**player-facing functions**:

```solidity
// Player initiates draw (pays cost)
function drawMysteryCard() external
{
    // Backend listens to CardDrawn event and posts effect
}

// Player pays to shuffle
function shuffleMysteryDeck() external{}
```

**"Oracle-only" functions (backend posts effects)**:

- resolve instant card
- resolve modifier card
- resolve resource card

### Backend (actor) responsibilities

**Deck initialization**:

- Query MysteryCardCatalog for enabled cards
- Remove excluded cards per tournament params
- Store initial list in actor state
- Request Pyth Entropy VRF seed
- Combine VRF seed with backend secret (shuffle_seed)
- Shuffle deck using PRNG with shuffle_seed
- Store shuffled deck in actor state

**Card draw processing**:

1. Listen for `CardDrawn` event
2. Extract: player, drawIndex
3. Determine card: `cardIndex = PRNG(shuffle_seed, drawIndex) % cardsRemaining`
4. Query card definition (use actor state ; if not possible, query chain data)
5. Calculate effect based on card category
6. Post effect to appropriate resolve function (instant/modifier/resource)
7. Update internal deck state (remove drawn card)
8. Update actor state

**Modifier tracking**:

- Maintain player modifier state in sync with contract
- When combat/trade occurs, check for triggered modifiers
- Include modifier effects in combat results
- Post modifier resolution to contract

**Shuffle handling**:

1. Listen for `DeckShuffled` event (player paid to shuffle)
2. Request new Pyth Entropy seed
3. Generate new shuffle seed with backend secret
4. Re-shuffle remaining cards with new seed
5. Update internal deck order

**Verifiability publication**:

- At tournament end, publish full shuffle seeds (all shuffles)

### Security considerations

**Draw blocking**:

- Players with active modifiers can't draw (prevents stacking)
- Combat/trade/exit not blocked by active modifiers
- Modifiers auto-resolve on trigger (no manual action needed)

**Deck depletion**:

- Drawing from empty deck reverts
- Shuffle only works if cards remain
- Players can't grief by depleting deck (costs coins)

**Effect validation**:

- Backend can't give impossible effects (validated by contract)
- Life/coin changes clamped to valid ranges
- Resource cards validate card type exists

### Flow diagram

```
Tournament starts
  THEN
Backend initializes deck (query registry, remove exclusions, shuffle with Pyth + secret)
  THEN
Backend posts seed commitment onchain
  THEN
DeckInitialized event emitted
  THEN
---
Player A wants to draw card
  THEN
Player A calls drawMysteryCard() (pays cost)
  THEN
Contract validates: no active modifier, deck not empty
  THEN
Contract emits CardDrawn(player, drawIndex, cost)
  THEN
Backend listens to event
  THEN
Backend calculates: cardIndex = PRNG(seed, drawIndex) % remaining
  THEN
Backend queries card definition from registry
  THEN
Backend determines card category:
    │
    ├─→ INSTANT: Calculate effect, call resolveInstantCard()
    │            Contract applies effect immediately
    │            hasActiveModifier remains false
    │            Player can draw again
    │
    ├─→ MODIFIER: Store trigger/effect, call resolveModifierCard()
    │             Contract sets hasActiveModifier = true
    │             Player CANNOT draw until modifier resolves
    │             Modifier waits for trigger (fight/trade/etc)
    │
    └─→ RESOURCE: Determine card type, call resolveResourceCard()
                  Contract adds card to player's hand (hidden type)
                  hasActiveModifier remains false
                  Player can draw again
  THEN
---
Later: Player A enters combat
  THEN
Player A has OnNextFight modifier active
  THEN
Combat system checks for modifiers
  THEN
Modifier effect applied during fight
  THEN
Modifier removed from activeModifier mapping
  THEN
hasActiveModifier set to false
  THEN
Player A can now draw mystery cards again
  THEN
---
Tournament ends
  THEN
Backend publishes full shuffle seeds
  THEN
Anyone can verify:
  - Reconstruct deck order from seeds
  - Verify each draw used correct PRNG index
  - Confirm backend didn't cheat
```

### Testing strategy

**Unit tests (Solidity)**:

- `test_DrawCard_Success()`
- `test_DrawCard_InsufficientCoins_Reverts()`
- `test_DrawCard_EmptyDeck_Reverts()`
- `test_DrawCard_HasActiveModifier_Reverts()`
- `test_ApplyInstantCard_UpdatesState()`
- `test_ApplyModifierCard_SetsFlag()`
- `test_ApplyModifierCard_SlotOccupied_Reverts()`
- `test_ApplyResourceCard_IncreasesCards()`
- `test_ResolveModifier_ClearsFlag()`
- `test_ShuffleDeck_UpdatesCommitment()`
- `test_ShuffleDeck_InsufficientCoins_Reverts()`

**Integration tests (TypeScript)**:

- Draw multiple cards in sequence
- Draw card, trigger modifier in combat, draw again
- Multiple players drawing concurrently
- Deck depletion (draw until empty)
- Shuffle mid-game, continue drawing
- Tournament end with active modifiers

**Backend tests (Rivet/TypeScript)**:

- Deck initialization with exclusions
- PRNG consistency (same seed = same order)
- Card draw determination
- Effect calculation for all card types
- Modifier tracking across actions
- Seed publication and verification
- Replay attack prevention

### Initial card catalog (starter)

**Instant cards (8)**:
Gain 5% of your coin
Gain 15% of your coins
Lose 10% of your coins
Lose 15% of your
Gain 1 life
Lose 1 life
Draw cost refunded, draw again
Lose 40% of your coins
Gain 20% of your coins (rare)
No effect (dud card)

**Modifier cards (9)**:

(OnNextFight): Prevent ALL life loss this fight
(OnNextWin): Winner takes 2 lives instead of 1
(OnNextLoss): Loser doesn't lose a life
(OnNextFight): Swap winner and loser
(OnNextWin): Winner gains +2 lives, but loser loses 2 lives
(OnNextWin): Winner steals 25% coins from loser
(OnTrade): Gain 5% coins when accepting any trade
(OnTrade): Gain 5% coins when accepting any trade
(OnDeckDraw): Next card draw costs 0 coins

**Resource cards (3)**:

1. **Rock Card**: Adds 1 rock to your hand
2. **Paper Card**: Adds 1 paper to your hand
3. **Scissors Card**: Adds 1 scissors to your hand
