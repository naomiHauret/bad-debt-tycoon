# Game design document

**What:** Competitive elimination game where players fight using rock-paper-scissors in a collapsing economy.

**Goal:** Be one of the few who successfully exit before going bankrupt and losing your stake.

## Game mechanics

0. **Tournament design**

   - Creator defines tournament rules :
     - duration
     - minimum/maximum players
     - stake (minimum, maximum, coin)
       - on the coin: only 1 coin is accepted per tournament (from whitelist: PYUSD, USDC, GHO)
     - decay rate
     - start conditions (ALL enabled conditions must be met):
       - player count threshold
       - pool prize threshold
       - date/time threshold
     - player resources :
       - amount of lives (eg 5 lives)
       - deck size per type (eg a deck of 10 means 10 rock, 10 paper, 10 scissors)
       - coin conversion rate (eg, 1 PYUSD staked = 100 in-game coins)
     - common exit conditions
     - available cards in the shared deck
     - creator fee (0-5%)

   **Fees:**

   - Platform fee: Set globally by platform admin (0.5-5%), applies to tournaments created after fee - change
   - Creator fee: Configurable per tournament (0-5%)
   - Total max: 10% combined

1. **Setup (pre joining game)**

   - Players join by staking a whitelisted stablecoin (PYUSD/USDC/GHO)

   **Setup (when game)**

   - Each player is randomly assigned a secret objective <mark>(@todo: implement in future phase)</mark>
   - Each player receives their resources
   - Lives: As configured by tournament (eg 5 lives)
   - Cards: As configured by tournament (eg 10 rock, 10 paper, 10 scissors)
   - Coins: stake amount \* conversion rate (eg 100 PYUSD \* 1 = 100 coins)

2. **Active phase**
   Players cycle through these actions until tournament ends :

   **A. Fight**

   - Challenge another player or get matched
   - Rock paper scissors fight
   - Winner: +1 life, Loser: -1 life
   - Both cards are destroyed when used
   - Mystery card effects may apply

   **B. Manage resources**

   - **Lives:** Gain from wins, lose from losses ; need minimum amount to exit (configured per tournament, eg need >=3 lives to exit)
   - **Coins:** Start with stake \* rate, decay applies, needed for exit
   - **Cards:** Start with configured amount per type (eg: 4 rock/ 4 paper/ 4 scissors), must have 0 of each type in hand to exit
   - **Debt:** Take loans (life <> in-game currency), must repay before exit

   **C. Economic actions**

   - **Trade:** Offer/accept trades with other players (lives for in-game currency, etc.)
   - **Bribe:** Pay in-game currency to see opponent's cards/objective/debt
   - **Draw mystery card:** Pay N in-game currency amount, get random effect
     - Match modifiers (eg: "Double or nothing", "Insurance", "Reversal"...)
     - Economic effects (eg: "Debt Forgiveness", "Windfall", "Bankruptcy"...)
     - Chaos effects (eg: "Forced match", "Peek deck", "rule change"...)
   - **Manipulate deck:** Add cards, remove top card, shuffle, peek
   - (nice to have) **Take loan:** Convert lives <> in-game currency, incur debt with interest

   **D. Crafting (optional)**

   - Combine specific cards to obtain 1 super card (Boulder/Scroll/Blade)
   - Super cards beat 2 types, but increase exit requirement

   **E. Automatic events**

   - **Decay through time**: All players lose N in-game currency (eg -5/hour)
   - **Exit cost compound**: Cost = stake _ (1 + 0.1 _ hours)
   - **Phase changes**: Every 6-8 hours, rules modify (eg "Rock dominance")

3. **Exit conditions**
   Player can exit when ALL met:

   - Required amount of lives (+ crafts made)
   - 0 cards remaining
   - Coins >= exit cost (compounds hourly)
   - Debt = 0 (all loans repaid)

@todo: They can also exit earlier if their secret objective is completed.

4. **Tournament end**

   - Time expires (duration reached)
   - Winners = players who successfully exited
   - Losers = anyone that didn't exit

5. **Prize distribution**

   - Platform fee (eg: 1% ) and creator fee (eg: 3%) are deducted
   - Remaining pool split among winners
   - Winners manually claim their share

6. **Cancellation/reinbursment**
   When a game start conditions are NOT met by its start time :
   - Players that entered can manually claim back their stake without a loss

### Keys game concepts

#### Resources

- **Lives:** Win condition, gained from fights, lost from losses. Initial amount configured per tournament.
- **Coins (in-game currency):** Economy unit, derived from stake \* conversion rate, decay over time, needed for exit, loans, and purchases
- **Cards:** Consumable ammo for fights, the initial deck size is configured per tournament (eg 10 of each, there can't be more/less of one type) ; can be traded and loaned ; must have 0 in hand to exit
- **Debt:** Liability from loans, blocks exit until repaid

#### Time pressure

- **Hourly decay:** Everyone loses X coins/hour (eg -5)
- **Exit cost compound:** Cost increases ~10% per hour
- **Phase changes:** Rules modify every N seconds
- **Tournament timer:** Hard deadline for exit

## Information asymmetry

- **Secret objectives:** Only you know your win condition
- **Hidden resources:** Can't see others' exact cards/debt
- **Bribes:** Pay to reveal opponent info
- **Mystery deck:** Unknown card order until drawn

## Social dynamics

- **Trading:** Negotiate exchanges (trust required)
- **Bribes:** Information market (eg pay a player 40 coin to see 5 of their cards)
- **Forced matches:** (nice to have) Mystery cards can make players fight
- **Alliances:** Informal (no enforcement mechanism)

## Win conditions (secret objectives)

Examples:

- **Survivor:** Just exit (easiest)
- **Tyrant:** Eliminate X players before exiting
- **Hoarder:** Exit with Y+ coins
- **Minimalist:** Exit with exactly 3 lives

## Exit methods

### Method 1: Successful exit (winner)

Requirements:

- Equal or above amount of required lives
- 0 cards remaining
- Coins equal or above the exit cost
- Debt = 0

Result: Marked as winner, eligible for prize share.

### Method 2: Early successful exit

Same requirements as regular exit, however, the player can exit early as a winner with 0 penalty if their secret objective is completed.

Result: Marked as winner, eligible for prize share.

### Method 3: Forfeit

Requirements:

- Tournament must allow forfeit (params.forfeitAllowed)
- Cannot have already exited successfully

Process:

1. Calculate penalty based on time remaining
2. Penalty = MAX \* (timeRemaining / duration), but >= MIN
3. Penalty goes to prize pool
4. Receive: stake - penalty
5. Marked as eliminated (not a winner)

Example:

- Stake: 100 PYUSD
- Max penalty: 80%, Min penalty: 10%
- Forfeit at 50% time remaining
- Penalty: 40 PYUSD (80% \* 50%)
- Receive: 60 PYUSD back

### Method 4: Fail to exit (Loser)

- Tournament ends
- Did not exit successfully
- Did not forfeit
- Receive: 0 (full stake goes to prize pool)

## Features grouping & breakdown

- **Tournament management**: Design, lifecycle, player entry/exit, prizes & reinbursments
- **Player resources**: Lives, in-game currency, cards, debt tracking
- **(Active) Combat system**: RPS matches, card burning, crafting
- **(Passive) Economic system**: Decay, exit costs
- **Player-to-player interaction**: Trades, bribes
- **Mystery shared deck**: Deck init, drawing, effects, manipulation
- **Objectives & phases**: Secret objectives, rule changes
- (nice to have) **Loan system**: Borrowing, debt, interest, repayment

## Technical decisions

### Architecture

- **Hybrid approach:** Onchain (Arbitrum Sepolia) for SOME of the state, backend for coordination
- **Match resolution:** Backend coordinates commit-reveal, posts results onchain
- **Mystery deck:** Backend manages order, uses RNG for verifiable shuffle seed
- **State sync:** Backend listens to chain events, updates database, handles reconciliation

### Core mechanics

- No in-game currency coin minting, only decay (except trades)
- **Card burning:** Every match burns cards, forces scarcity
- **Exit requirements:**0 cards in hand, sufficient lives,, sufficient in-game currency, no debt
- **Early exit**: Exit requirements + meet objective
- **No elimination:** Players stay in until tournament ends (can't be kicked out)

### Core tournament rules

- **Duration:** Minimum 20 minutes, no maximum (configurable)
- **Stakes:** Min/max bounds (optional), supports variance between players
- **Start conditions:** **ALL enabled conditions must be met:**
  - Player count threshold
  - Pool amount threshold
  - Timestamp (start/end)
  - At least ONE condition must be enabled
- **Prize claiming:** Manual (not automatic -> later improvement)
- **Cancellation:** If start conditions not met after start time, players can refund
- **Fees:**
  - Platform fee: 0.5-5% (set globally) ; if the platform fee changes WHILE a tournament is ongoing, its platform fee value won't change (only tournaments created AFTER the platform fee update will have this value)
  - Creator fee: 0-5% (per tournament)
  - Total max: 10%
- **Whitelisted stablecoins only:** Whitelisted stablecoins only: PYUSD, USDC, GHO (no volatility risk, limited depeg risk, easy access to on/offramp and liquidity)
- **Tournament creator chooses**: Single token per tournament from the whitelist

### Tokens whitelist

For now, only whitelisted stablecoins will be supported as potential stakes :

- PYUSD
- USDC
- GHO

### Randomness (w/ Pyth Entropy)

- **Secret objectives:** Assigned at tournament start
- **Rule phases**
- **Mystery deck shuffle:** Determines card draw order

### Backend trust model

- **What backend CAN'T cheat:** Deck modifications, draws, payments (all logged on-chain)
- **What backend COULD cheat:** Mystery deck card order (though mitigated by Pyth seed commitment)
