# Trading system

## User stories breakdown

### Trade offer creation

**As a player with resources**,
I want to **offer a trade to another player or post it publicly**,
So that **I can exchange resources strategically and potentially exit as a winner**.

```
GIVEN a tournament is in "Active" status
  AND I am an "Active" player
  AND I have sufficient resources to offer
  AND I have NOT exceeded max active trades limit (1)
WHEN I create a trade offer specifying:
  - Target player address (or address(0) for public trade)
  - Resources I'm offering (coins, lives, totalCards)
  - Resources I'm requesting (coins, lives, totalCards)
  - Expiration duration (must be > current time and within tournament bounds)
THEN my resources are validated (I have what I'm offering)
  AND a new trade offer is created with unique tradeId
  AND the offer is marked as active
  AND my active trade count increments by 1
  AND `TradeOffered(tradeId, offerer, target, offering, requesting, expiresAt)` event is emitted
```

**As a player**,
I want to **create public trades that anyone can accept**,
So that **I can find trading partners without knowing specific addresses**.

```
GIVEN I want to create a public trade
WHEN I call offerTrade with target = address(0)
THEN any active player can accept the trade
  AND the first player to accept gets the trade
  AND `TradeOffered` event shows target as address(0)
```

**As a player**,
I want to **create directed trades to specific players**,
So that **I can negotiate deals with trusted players**.

```
GIVEN I want to trade with a specific player
WHEN I call offerTrade with target = playerAddress
THEN only that specific player can accept the trade
  AND other players cannot accept even if they see the offer
  AND `TradeOffered` event shows the target player address
```

### Trade offer limits

**As the game system**,
I want to **limit the number of active trades per player**,
So that **players don't spam trades or lock up resources indefinitely**.

```
GIVEN the tournament has a max active trades limit (1)
  AND I already have that many active trades
WHEN I attempt to create another trade
THEN the transaction reverts with "Max active trades reached"
  AND I must wait for existing trades to be accepted/cancelled/expired
```

### Trade acceptance (two-phase reveal)

**As the target of a trade offer**,
I want to **accept a trade by revealing exact card types I'm giving and receiving**,
So that **the trade completes with full transparency about card types**.

```
GIVEN a trade offer exists and is active
  AND I am the target (or it's a public trade)
  AND the offer has not expired
  AND both parties still have the required resources
WHEN I accept the trade by specifying:
  - Offerer's card selection (which types they give: X rock, Y paper, Z scissors)
  - My card selection (which types I give: X rock, Y paper, Z scissors)
THEN the system validates:
  - Offerer card selection totals match offered totalCards
  - My card selection totals match requested totalCards
  - Offerer has those specific card types available
  - I have those specific card types available
  - Both parties have sufficient coins and lives
THEN resources are exchanged atomically:
  - Coins transferred bidirectionally
  - Lives transferred bidirectionally
  - Specific card types transferred as specified
THEN the trade is marked as completed
  AND both players' active trade counts decrement
  AND `TradeAccepted(tradeId, acceptor, offererCards, acceptorCards)` event is emitted
  AND card types are now revealed in the event
```

### Trade cancellation

**As the offerer of a trade**,
I want to **cancel my active trade offer**,
So that **I can change my mind or free up my active trade slot**.

```
GIVEN I created a trade offer
  AND the trade is still active (not yet accepted)
WHEN I cancel the trade
THEN the trade is marked as cancelled
  AND my active trade count decrements
  AND `TradeCancelled(tradeId, offerer, timestamp)` event is emitted
```

**As a non-offerer**,
I want to **be prevented from cancelling others' trades**,
So that **only the trade creator can cancel their offers**.

```
GIVEN a trade offer exists
  AND I am NOT the offerer
WHEN I attempt to cancel the trade
THEN the transaction reverts with "Only offerer can cancel"
```

### Trade expiration

**As the game system**,
I want to **automatically expire trades after their expiration time**,
So that **stale offers don't clutter the system**.

```
GIVEN a trade offer was created with expiration time
  AND current time >= expiration time
  AND the trade has not been accepted or cancelled
WHEN anyone attempts to accept the trade
THEN the transaction reverts with "Trade expired"
  AND the trade remains in "active" state but unacceptable
```

**As a player**,
I want to **clean up expired trades to free my trade slot**,
So that **I can create new trades after old ones expire**.

```
GIVEN one of my trades has expired
WHEN I call cleanupExpiredTrade(tradeId)
THEN the trade is marked as expired
  AND my active trade count decrements
  AND `TradeExpired(tradeId, timestamp)` event is emitted
```

### Resource validation

**As the game system**,
I want to **validate resources at both offer creation and acceptance**,
So that **trades can't complete if resources have changed**.

```
GIVEN a trade was offered with specific resources
  AND time has passed (resources may have changed via combat/decay)
WHEN someone accepts the trade
THEN the system re-validates both parties have required resources
  AND if validation fails, trade acceptance reverts
  AND the trade remains active for retry later
  AND `TradeRejected(tradeId, reason)` event is emitted
```

### Information hiding in trades

**As a player**,
I want to **offer cards without revealing their types initially**,
So that **the two-phase reveal maintains strategic advantage**.

```
GIVEN I offer 3 cards in a trade
WHEN the offer is created
THEN only the total count (3) is public in the offer
  AND the specific types (rock/paper/scissors) are NOT revealed
  AND the types are only revealed when someone accepts
  AND the acceptor specifies which types they want/give
```

### Trade with modifiers

**As a player with an active mystery deck modifier**,
I want to **still be able to trade even with a pending modifier**,
So that **modifiers don't completely block economic activity**.

```
GIVEN I have an active modifier (currentModifier.exists = true)
WHEN I offer or accept a trade
THEN the trade proceeds normally
  AND if the modifier trigger is OnTrade, it applies during acceptance
  AND after OnTrade modifier resolves, currentModifier is cleared
```

**As the game system**,
I want to **apply OnTrade modifiers when trades are accepted**,
So that **mystery cards can affect trading outcomes**.

```
GIVEN a player has an OnTrade modifier active
WHEN they accept a trade
THEN the modifier effect is applied (eg: "gain 30 coins")
  AND the modifier is cleared after resolution
  AND the trade completes with modifier effects included
  AND `ModifierResolved(player, cardId, trigger, effect)` event is emitted
```

## Technical breakdown

The trading system enables **bilateral resource exchange** between players within a tournament. It operates entirely onchain with two-phase card type revelation to maintain information asymmetry while ensuring verifiable exchanges.

### Core mechanics

**Trade lifecycle**:

1. **Creation**: Player creates offer with total resources (card types hidden)
2. **Discovery**: Other players see offer (public or directed)
3. **Acceptance**: Target accepts and reveals exact card types for both parties
4. **Execution**: Resources swap atomically after validation
5. **Completion**: Trade marked done, both parties' trade slots freed

**Two-phase card revelation**:

- **Phase 1 (Offer)**: "I'll trade 3 cards for 2 lives"
  - Card count public, types hidden
  - Creates information asymmetry
  - Target doesn't know what cards they'll get
- **Phase 2 (Acceptance)**: Acceptor specifies exact types
  - Offerer cards: "2 rock + 1 paper"
  - Acceptor cards: "1 scissors + 0 rock + 0 paper"
  - Both parties see types before trade finalizes
  - Either can still reject if they don't like the types

### Resource types

**Tradeable resources**:

- **Coins** (in-game currency)
- **Lives** (combat resource)
- **Cards** (totalCards count, specific types revealed on acceptance)

**Non-tradeable**:

- Mystery deck modifiers (these are personal)
- Player status/flags

### Trade targeting

**Public trades** (`target = address(0)`):

- Anyone can accept
- First-come-first-served

**Directed trades** (`target = specific address`):

- Only target can accept
- Private negotiation
- Can request specific resources from specific players

### Trade limits

**Per-player active trade limit**:

- 1 active trade at a time
- Prevents spam and resource lock-up
- Encourages decisive trading
- Slots freed when trades complete/cancel/expire

**Expiration duration**:

- Set globally per tournament (eg: 1 decay interval)
- Players can set shorter durations within bounds
- Prevents stale offers cluttering system
- Manual cleanup needed after expiration

### Information hiding

**What's public**:

- Trade offer exists
- Total coins/lives/cards being offered/requested
- Who is offering (and target if directed)
- Expiration time

**What's hidden**:

- Specific card types in the offer (until acceptance)
- Which exact cards will be exchanged
- Other players' exact card breakdowns

**Why hide**:

- Maintains strategic uncertainty
- Prevents perfect information
- Encourages risk-taking in trades
- Creates value in "blind" exchanges

### Atomic execution

All trades execute **atomically** - either everything succeeds or nothing happens.
No partial trades, no race conditions, no double-spends.

## System requirements

### `TournamentCore.sol`

```solidity
struct Params {
    // ... existing params
    uint256 tradeExpiryDuration; // How long trades stay active (eg: 1 decay interval)
    uint8 maxActiveTradesPerPlayer; // Max concurrent trades (eg: 1)
}

struct TradeAsset {
    uint256 coins;
    uint8 lives;
    uint8 totalCards;  // Total count only, types hidden
}

struct CardSelection {
    uint8 rock;
    uint8 paper;
    uint8 scissors;
    // Must sum to totalCards
}

struct TradeOffer {
    address offerer;
    address target;  // address(0) = public trade
    TradeAsset offering;
    TradeAsset requesting;
    uint32 createdAt;
    uint32 expiresAt;
    TradeStatus status;
    bool exists;
}

enum TradeStatus {
    Active,
    Completed,
    Cancelled,
    Expired
}
```

### `TournamentTrading.sol`

**Goal**: Handle trade offers, acceptance with card revelation, validation, and atomic resource exchange

**Who uses it**: Tournament contract, called by players

**How it's used**:

- Players create trade offers (public or directed)
- Players accept trades with card type specifications
- Players cancel their own offers
- System validates resources and executes atomic swaps

### Flow diagram

```
Player A creates trade offer
 THEN
"I offer: 3 cards + 50 coins"
"I want: 2 lives"
 THEN
Target: Player B (or address(0) for public)
 THEN
Contract validates:
  - Player A has 3 cards + 50 coins
  - Player A under active trade limit
  - Expiry within bounds
 THEN
Trade created with ID #123
TradeOffered event emitted

---
Player B sees trade offer
 THEN
Player B wants to accept
 THEN
Player B specifies card types:
  - "Player A gives: 2 rock + 1 paper"
  - "I give: 0 rock + 0 paper + 0 scissors" (just lives, no cards)
 THEN
Player B calls acceptTrade(123, offererCards, acceptorCards)
 THEN
Contract validates:
  - Trade still active
  - Not expired
  - Player B is allowed to accept
  - Card selections match totals
  - Player A still has 2 rock + 1 paper
  - Player B has 2 lives
 THEN
Check for OnTrade modifiers:
  - Player B has "Trade Bonus" (+30 coins)
  - Modifier applied
  - Player B gets +30 coins bonus
  - Modifier cleared
 THEN
Execute atomic swap:
  - Player A: -2 rock, -1 paper, -50 coins, +2 lives
  - Player B: +2 rock, +1 paper, +50 coins (+ 30 bonus), -2 lives
 THEN
Mark trade as Completed
Decrement both players' active trade counts
 THEN
TradeAccepted event emitted (with card types revealed)
 THEN
Both players see updated resources
Trade slot freed for both players
```

### Testing strategy

**Integration tests**:

- Multiple concurrent trades
- Trade + combat + decay interactions
- Trade with mystery deck modifiers
- Trade expiration and cleanup
- Public vs directed trades
- Edge case: Trade during tournament end

**Edge cases to test**:

- Player exits with active trades
- Resources decay between offer and acceptance
- Player loses fight (resources change) before trade accepted
- Both players try to accept same public trade (race condition)
- Card type validation (can't give more than you have)
