# Combat flow

## User stories breakdown

### Matchmaking

**As a tournament registered player**
I want to **signal to other players that I am looking for an opponent**
so that we can I can **receive an invitation to play a round of rock paper scissors.**

**As a tournament registered player**
I want to **find a player open to fight**
so that I can **send an invitation to play a round of rock paper scissors.**

**As a tournament registered player**
I want to **accept an invitation to play rock paper scissors from another player**
so that I can **proceed to play rock paper scissors immediatly with that other player.**

**As a tournament registered player**
I want to **reject an invitation to play rock paper scissors from another player**
so that I can **control who I want to fight and when.**

### Battle round

**As a challenger in a rock paper scissors battle**,
I want to **see my different available moves**
so that I can **decide which move I want to play next.**

**As a challenger in a rock paper scissors battle**,
I want to **lock my move**
so that the **game can continue.**

**As a the game system**,
I want to **hide player moves from their opponents**
so that **the battle can play fairly and no one can cheat.**

**As a the game system**,
I want to **burn cards immediatly once a battle resolves**
so that **players can't reuse their cards.**

**As a the game system**,
I want to **determine the outcome of the game based on the cards played and the active effects**
so that **the winner can be determined.**

**As a the game system**,
I want to **redistribute assets between opponents based on the game outcome and the active effects**
so that **the tournament can continue.**

## Technical breakdown

The combat flow requires 2 main features :

- absolute privacy: players should NOT be able to know what others played

  - this ensures players can't cheat during a battle
  - this ensures other players don't know what cards a certain player has left in their hands, opening the door for bribes

- real-time matchmakings: players should be able to quickly find opponents and battle with them

### System requirements

This system would be built following a hybrid model: part of it onchain, part of it on a more "traditional" backend.

While players resources are tracked onchain in the `Tournament` contract, the actual implementation of the combat flow and matchmaking would fit [the actor model](https://en.wikipedia.org/wiki/Actor_model), with a new tournament actor being spawned when a tournament is created or starting.
