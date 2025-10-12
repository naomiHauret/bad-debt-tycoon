# Bad Debt Tycoon

[ETHOnline 2025 hackathon entry](https://ethglobal.com/events/ethonline2025).

> A resource management battle royale economy sim where you have to claw your way out of debt by playing rock paper scissors. Whether you play, trade with other players or tamper with the shared central deck is up to you - as long as you have what it takes to survive til the end.

### Genres

- "Tycoon" & economy sim
- Real-time strategy
- Battle royale
- Resource management

### Influences (story, game mechanics, aesthetics...)

- [Stonks-9800](https://store.steampowered.com/app/1539140/STONKS9800_Stock_Market_Simulator/)
- [GTA Vice City](https://en.wikipedia.org/wiki/Grand_Theft_Auto:_Vice_City)
- [Kaiji](https://en.wikipedia.org/wiki/Tobaku_Mokushiroku_Kaiji)
- [Luigi's casino](https://sm64-conspiracies.fandom.com/wiki/Luigi%27s_Casino)
- [Celadon City casino](https://bulbapedia.bulbagarden.net/wiki/Celadon_Game_Corner)
- [PC-98 vibe](https://www.pinterest.com/ideas/pc98-pc-games/950955929444/)

### Target audience

ESRB: 18+, player can gamble, including betting or wagering real cash or currency.

- Risk takers
- Social players

### Mechanics & game loops

**Bad Debt Tycoon** (bdt) is a dead simple (but secretly complex), stupid [battle royale game](https://en.wikipedia.org/wiki/Battle_royal) of [rock paper scissors](https://en.wikipedia.org/wiki/Rock_paper_scissors), with a [player-led economy](https://en.wikipedia.org/wiki/Virtual_economy) born from players decisions and [emergent gameplay](https://en.wikipedia.org/wiki/Emergent_gameplay).

Players can enter a battle royale (each player for themselves) by putting at stake a certain amount of a token. Against that token, they receive :

- an amount of in-game currency (that can only can be used in this battle royale game)
- a number of in-game "lives"
- a deck of cards, with an equal amount of rock, paper, and scissors cards
- a secret randomly assigned objective card

**Players "fights" each others with a game of rock paper scissors**, with the loser giving one of their "life" to the other player, and each played card is destroyed. They can trade everything with each others: lives, cards, currency... And bribe each others to reveal some information about their status (what cards they have left, what is their secret win condition, their debt status).

**To win, players must escape with at least N lives, 0 cards remaining, and enough in-game currency to cover their exit fee** (the amount they received at the beginning) OR complete their hidden objective (eg: having 6 lives, beating 4 players without a single loss...). The twist is, the game economy is designed to collapse. Every given unit of time (eg: every 20 minutes, every hour etc.), **ALL players lose some of their in-game currency automatically**. No new coins ever enter the system, and at the same time, the exit cost rises with [compound interest](https://en.wikipedia.org/wiki/Compound_interest).

Along with the regular cards, **players can craft "super cards"** (eg: combine 2 rocks into a "boulder" that beats rock AND paper for instance), but **this changes their exit requirements** by increasing how many cards they need to burn to exit.

Additionally to their own deck, there's also **a shared deck that anyone can draw from by using the in-game currency**. These cards have different effects that can drastically change the game for the person that draws from it (draw an additional scissors card, decrease/increase their debt, allow them to keep their star in the next face off if they lose, lose all their coins but gain an additional 6 lives...). Besides drawing from that central deck, all players can use their in-game currency to **add specific cards to this deck, shuffle it, or remove cards**. So players can stack it in their favor, or add chaos cards.

The game economy is player-driven, meaning not only players can trade between each others, but also use the in-game lending market to for instance trade 1 life for 50 coins instantly... However, interacting with this entity is a double-edge sword, as they'd have to repay based on how much time there's left in the game, and failing to pay mean they won't be able to exit. This creates debt spirals where people borrow to survive, then need to borrow more to repay the first loan.

Finally, the game introduces some randomness by changing rules every now and then: maybe rock suddenly beats Paper AND Scissors. Or decay doubles. Or all coin amounts get cut in half.

Of course, **players can also decide to exit early, but they will forfeit a % of their stake** (unless they completed their objective card). If they stay until the end but didn't fulfill the requirements of the tournament, **they lose their stake, which is added to the winners pool**.

Winners get their stake back, + split the winners pool between themselves.

Ultimately, the depth comes from player agency: trade lives for currency, take out loans (creating debt spirals), draw from the random central card deck (with whatever that entails to) or manipulate it, bribe others. The secret win conditions and rule changes add another layer of strategy and force players to do something. It's a fair game of pure luck that requires no skills but with rules designed to be unfair... and that players must bend as much as they can.
