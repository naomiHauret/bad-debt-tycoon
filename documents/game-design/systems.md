# System design

## Role of each contracts breakdown

### TournamentRegistry: our global tournament tracker

**TournamentRegistry** is a list of all the tournaments that exist. It tracks them by their status, along with how to find their modules.

The registry does not create tournaments, run tournaments or validate game logic.

### TournamentFactory: our ruleset maker

**TournamentFactory** is a builder. It ensures a "candidate" tournament is valid, then creates its systems (1 system = 5 underlying contracts) by deploy and initializing them, and registers it with the Registry. After that, Factory's job is done and it doesn't manage the tournament afterwards.

### TournamentHub: the heart of a tournament/the guy you need to talk to to do something in a tournament

Hub can be seen as the main game controller. It manages players, their resources (lives, coins, cards), coordinates other modules (Combat, Deck, Trading) and handles the tournament status (if the tournament should lock new entries, when the window exit can open, when the tournament should end, if a player can claim a prize...).

### Modules: specialized workers

Modules are experts in their own domain, and handle ONE specific game mechanic :

- `Combat`: resolves fights, applies modifiers
- `MysteryDeck`: Card draws, effects, deck state
- `Trading`: Trade offers, acceptances
- `Randomizer`: Provides random number from Pyth Entropy to act as a seed

They cannot act independently and are always called by or authorized by `Hub`.

## Deployment & validation flow

### Phase 1: One-time system setup (platform runner)

The **platform runner** wallet deploys:

1. `TournamentTokenWhitelist`:
   - the list of ERC20 tokens authorized to be used as stake
   - the platform runner manages this list (add/pause tokens)
   - Tokens can be paused individually. The pause system ensures active tournaments with that token can continue to operate normally (players can forfeit, claim prizes without a problem) while reducing exposure for new tournaments.
2. `TournamentDeckCatalog`:
   - the list of all mystery cards and secret objectives that can be used in tournaments
   - the platform runner manages this catalog (add/pause cards and objectives)
   - Like tokens, individual cards and objectives can be paused to help rebalance the game system for new tournaments.
3. `TournamentRegistry`

4. Implementation contracts :

- `Hub`
- `Combat`
- `Deck`
- `Trading`
- `Randomizer`

5. `TournamentFactory` (with all addresses above) :

- the `Factory` validates that all contracts passed have a valid address
- it also validates the platform fee amount (<= 5%)

The platform runners configures:

- Authorizing contracts to be a validated tournament factory: `Registry.grantFactoryRole(factory)`
- Whitelisting tokens: `Whitelist.addToken(USDC, PYUSD, GHO)`
- Adding cards/objectives: `DeckCatalog.registerCards([...])`

### Phase 2: Tournament Creation (Per Tournament) (game creator/designer)

Tournament creator calls `Factory.createTournamentSystem(params)`, which under the hood :

1. Validates all tournament parameters

```
Factory._validateParams(params)  # VALIDATION CHECKPOINT n°1
  ├─ Time: startTimestamp, duration, interval
  ├─ Players: min/max players
  ├─ Economic: stake token whitelisted, min/max stakes
  ├─ Combat: lives, cards, exit requirements
  ├─ Fees: creator fee + platform fee <= 10%
  ├─ Forfeit: penalty bounds, activated or not
  └─ Mystery Deck: catalog, costs, oracle != 0
```

Before any deployment, `Factory` validates ALL tournament parameters and reverts the entire transaction if ANY parameter invalid. It ensures the validity and logical coherence of :

- Time bounds and values (start > now, duration >= min, game interval duration, that at least intervals fit within duration)
- Player bounds (min >= 2, max >= min, start <= max)
- Token state whitelist status (queries whitelist contract)
- Stakes coherence (min <= max if both set)
- Economic sanity (conversion rate > 0, decay > 0)
- Combat viability (lives > 0, cards in bounds, exit requirements)
- Fees amount (creator <= 5%, combined <= 10%)
- Forfeit consistency (if disabled, penalties must be 0)
- Deck config validity (catalog exists, costs > 0, oracle set)

**It does NOT validate module initialization** (each module is responsible of its own initialization).

If the validation is successful (no errors), `Factory` can then proceed to deploys 5 minimal module proxies:

- Hub = `Clones.clone(hubImplementation)`
- Combat = `Clones.clone(combatImplementation)`
- MysteryDeck = `Clones.clone(mysteryDeckImplementation)`
- Trading = `Clones.clone(tradingImplementation)`
- Randomizer = `Clones.clone(randomizerImplementation)`

When the proxies deployed, Factory still needs to initialize them individually :

1. Hub module

```
Hub.initialize(params, creator, combat, deck, trading, randomizer, ...)
     ├─ VALIDATION CHECKPOINT n°2
     ├─ Validates module contracts addresses: combat != 0, deck != 0, trading != 0, randomizer != 0
     ├─ STORES: combat, mysteryDeck, trading, randomizer addresses
     ├─ AUTO-GRANTS: _grantModuleRole(combat), _grantModuleRole(mysteryDeck), _grantModuleRole(trading)
     └─ Initializes: params, creator, status = Open
```

After proxy deployment and BEFORE other modules, the `Hub` validates the other module addresses and grants them their appropriate role.

2. Combat module

```
Combat.initialize(hub, randomizer)
     ├─ VALIDATION: hub != 0, randomizer != 0
     └─ STORES: hub, randomizer
```

3. Mystery deck module

```
MysteryDeck.initialize(hub, catalog, randomizer, excludedCards, costs, oracle)
     ├─ VALIDATION: hub != 0, catalog != 0, randomizer != 0, oracle != 0
     ├─ VALIDATION: costs > 0
     ├─ VALIDATION: excludedCards.length <= MAX_EXCLUDED_CARDS
     └─ STORES: config, hub
```

4. Trading module

```
Trading.initialize(hub)
     ├─ VALIDATION: hub != 0
     └─ STORES: hub
```

5. Randomizer module

```
Randomizer.initialize(hub, pythEntropy)
     ├─ VALIDATION: hub != 0, pythEntropy != 0
     └─ STORES: hub, pythEntropy
```

With all the modules initialized, the `Factory` can register this entire system of inter-connected modules in the `Registry`

```
  Registry.registerTournamentSystem(hub, combat, deck, trading, randomizer)
    ├─ VALIDATION CHECKPOINT n°3
    ├─ Checks: msg.sender has factory role
    ├─ Validates: all 5 addresses != 0
    ├─ Checks: hub not already registered
    ├─ Checks: no module reused across tournaments (via _moduleToHub mapping)
    ├─ STORES: `TournamentSystem` struct
    ├─ STORES: Reverse lookups (all 5 modules -> hub)
    └─ STORES: Status tracking (hub -> Open status)
```

With all our tournament modules initialized, Registry can perform the final validation before our onchain game system goes live. It verifies the authorizations (factory role), validates all the modules addresses, check that the hub isn't already registered and that the modules aren't reused. If the validation passes, THEN FINALLY, we register the system in the Registry.

When the system is registered, our `Factory` emits an event `TournamentSystemCreated`, which contains all the underlying module addresses and useful information (hub, combat, deck, trading, randomizer, creator, token, start, duration). This is then captured by the backend, where an actor can spin the offchain system (another actor) for this tournament.
