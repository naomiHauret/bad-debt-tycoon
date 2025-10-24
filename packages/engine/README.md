# @bdt/engine

Smart contracts, data structures, assets & bootstrapping scripts for Bad Debt Tycoon onchain systems.
[Built with Hardhat V3](https://hardhat.org/docs/learn-more/whats-new).

## Pre-requisites

- A wallet (preferrably new, or at least one you don't use personally) with :
  - some Arbitrum Sepolia ETH for deployments
  - some PYUSD, USDC
- `node` installed
  - Ensure your `node` version is `>=22.10.0`
- Run `bun install` **at the root of the monorepo** (or use `pnpm`, `npm`, `yarn`... as you wish) to ensure your dependencies are installed

## Getting started

### Set and manage encrypted secrets

We use `keystore` to deal with secrets.
You'll need to set the values of the following variables:

```sh
ARBITRUM_SEPOLIA_RPC_URL # RPC URL for Arbitrum Sepolia
DANGER_DEPLOYER_TESTNET_PK # Private key of the wallet we'll use to deploy on testnet. This will also be the platform runner
DANGER_ORACLE_TESTNET_PK # Private key of the wallet we'll use on the backend
```

To do so, define your encrypted variables using `keystore`:

```sh
# in dev, use this
bunx hardhat keystore set --dev <VARIABLE NAME> # eg bunx hardhat keystore set --dev ARBITRUM_SEPOLIA_RPC_URL

# In prod, remove the --dev flag
# Note: the first time you run this command, it will prompt you to create a password for your keystore
# You'll need to enter this password everytime you add a new value
bunx hardhat keystore set <VARIABLE NAME>  # eg bunx hardhat keystore set ARBITRUM_SEPOLIA_RPC_URL
```

Verify your config with `bunx hardhat keystore list` (add `--dev` flag if necessary).

Refer to [the Hardhat docs on managing encrypted variables](https://hardhat.org/docs/learn-more/configuration-variables#managing-encrypted-variables) for the complete list of commands.

### Tests

> Pre-requisites: deploy the entire system using `bun run deploy:system:local` . This will deploy all contracts to a locally simulated chain and apply a few operations (whitelisting tokens, adding cards and objectives to the catalog...)

To run all the tests in the project, execute the following command:

```shell
bun run test # or `bunx hardhat test`

```

You can also selectively run the Solidity or `node:test` tests:

```shell
bun run test:solidity # or `bunx hardhat test solidity`
bun run test:nodejs # or `bunx hardhat test nodejs`
```

#### Deployment

Bad Debt Tycoon uses [Hardhat Ignition modules](https://hardhat.org/ignition/docs/getting-started#overview) to simplify contract deployments. Modules can be deployed to a locally simulated chain or to Arbitrum Sepolia/Base Sepolia.

To run the deployment to a chain:

```shell
bunx hardhat ignition deploy ignition/modules/<Module Name>.ts --network <network name>
# eg: bunx hardhat ignition deploy ignition/modules/DeckCatalog.ts --network arbitrumSepolia
```

```shell
# localhost example
# In terminal 1, start local node
bun hardhat node

# In terminal 2, deploy :)
bunx hardhat ignition deploy ignition/modules/<Module Name>.ts --network hardhat
# eg: bunx hardhat ignition deploy ignition/modules/DeckCatalog.ts --network hardhat

```

> When deploying to a chain (mainnet/testnet), you'll have to ensure the deploying account has funds to send the transaction. On hardhat localhost, no need to.

##### Deploying to a specific network (checklist)

Ensure the following are correctly configured :

- [ ] Token whitelist (`src/assets/tokens/<chain name>.ts`) ; this file is generated automatically, so if a token has erroned/outdated info, you'll have to edit them info in `src/assets/tokens/whitelist/<token name>/definition.json`, then run `bun generate:tokens` to regenerate the whitelist.

The whitelist is used in `./ignition/modules/TokenWhitelist.<chain name>.ts`, so make sure it's correct, otherwise you'll have to pause EACH wrong token manually with the deployer wallet.

- [ ] Catalog (`src/assets/catalog`) ; check cards and objectives definition ; you can always add/pause each card or objective as the platform runner

- [ ] Factory deployment parameters (`src/parameters/factory/factory.<chain name>.json`) :

```json
{
  // example values for Arbitrum Sepolia

  "pythEntropy": "0x549ebba8036ab746611b4ffa1423eb0a4df61440", // see Entropy docs for accurate value for your chain
  "entropyProvider": "0x6CC14824Ea2918f5De5C2f75A9Da968ad4BD6344", // see Entropy docs for accurate value for your chain
  "platformAdmin": "0xdf1195ef56a9a068f589b5EE5f6961242e358012", // the deployer wallet address
  "gameOracle": "0xe9478B0CD70A6ee4F4d801e7A4eC3705e3a6Bd41", // the backend wallet address
  "platformFeePercent": 2 // fee to apply, can't be > 5 (hardcoded) but can be updated as the platform runner
}
```

- [ ] Make sure both the oracle wallet and the platform runner wallets are different, uncompromised (fresh wallet is always better), not used anywhere else, and that they have enough ETH in them

Once all of the above is checked double checked, triple checked, you can run `bun run deploy:system:<chain name>` ; see `package.json` for the available networks. This will deploy the entire system and seed both the token whitelist and catalog with objectives and cards, using the values provided in `assets/`.

You should see the following in your terminal:

```
bun run deploy:system:arb:testnet
$ bun run deploy:tokenlist:arb:testnet && bun run deploy:catalog:arb:testnet && bun run deploy:registry:arb:testnet && bun run deploy:factory:arb:testnet
$ bun run generate:tokens && bunx hardhat ignition deploy ignition/modules/TokenWhitelist.arbitrum-sepolia.ts --network arbitrumSepolia
$ bun run ./src/assets/tokens/helpers/generate-tokens-lists.ts
Generated base-sepolia.ts with 1 tokens
Generated arbitrum-sepolia.ts with 2 tokens
```

Then for each contract, you'll be prompted `✔ Confirm deploy to network <network name> (<network id>)? … y/N` type `y` every time (... or `N` if you don't want the contract to be deployed).

You should see this once all the contracts are deployed successfully:

```
Deployed Addresses

TokenWhitelist#TournamentTokenWhitelist - 0x...
DeckCatalog#TournamentDeckCatalog - 0x...
Registry#TournamentRegistry - 0x...
TournamentFactorySystem#TournamentCombat - 0x...
TournamentFactorySystem#TournamentFactoryDeployment - 0x...
TournamentFactorySystem#TournamentFactoryValidation - 0x...
TournamentFactorySystem#TournamentLifecycle - 0x...
TournamentFactorySystem#TournamentMysteryDeck - 0x...
TournamentFactorySystem#TournamentPlayerActions - 0x...
TournamentFactorySystem#TournamentRandomizer - 0x...
TournamentFactorySystem#TournamentRefund - 0x...
TournamentFactorySystem#TournamentTrading - 0x...
TournamentFactorySystem#TournamentViews - 0x...
TournamentFactorySystem#TournamentHubPlayer - 0x...
TournamentFactorySystem#TournamentHubPrize - 0x...
TournamentFactorySystem#TournamentHubStatus - 0x...
TournamentFactorySystem#TournamentHub - 0x...
TournamentFactorySystem#TournamentFactory - 0x...
```

Congrats, your potentially exploitable code is now onchain, hope those tests were solid, have fun :)

## Development

```bash
# Start local blockchain
bun hardhat node

# Deploy contracts (in another terminal)
bun run deploy:system:local

# Run tests
bun run test
```

## Architecture

Bad Debt Tycoon uses a **modular smart contract architecture** with a hybrid onchain/offchain design. Each tournament consists of financial state tracked onchain and game logic coordinated by a trusted backend oracle that uses actors to coordinates actions.

Onchain, each tournament deploys 5 minimal proxy contracts:

- **Hub**: Owns player state, coordinates modules
- **Combat**: Manages battles between players
- **Mystery Deck**: Handles shared deck actions
- **Trading**: Facilitates resource exchanges
- **Randomizer**: Provides verifiable randomness

Modules communicate through the `Hub` via `updatePlayerResources()`. All state changes emit events that the backend consumes for reconciliation, meaning we have both trustless actions/information and trusted actions/information (via our trusted backend oracle) :

**Onchain (Trustless)**

- Stakes, prize pool, fees
- Player resources (lives, coins, total cards)
- Tournament lifecycle & status
- Exit/forfeit validation

**Offchain (trusted backend)**:

- Combat matchmaking & resolution
- Deck order & card effects (shuffling, adding, removing, peeking)
- Trade validation (specific card types)
- Game state reconciliation

The amount of cards in hand, lives and coins of a player are public and visible to all, while individual card breakdown (rock, paper, scissors) count are tracked offchain by the backend. Similarly, the shared mystery deck card count is visible to all, while the exact cards it contains and their order is done on the backend.

As for randomness, the game uses a hybrid approach to prevent prediction while maintaining some form of verifiability:

1. **Onchain VRF** (Pyth Entropy): Provides publicly visible random seed
2. **Backend secret**: the each tournament actor generates their own additional private seed (actor state is isolated, meaning an actor only has access to its own state)
3. **Combined PRNG**: Uses the onchain seed + backend secret for :
   - Player objective assignment
   - Mystery deck composition & shuffle order

This dual-seed approach ensures that even though the Pyth VRF output is public, the actual game outcomes (next card drawn, specific objectives) remain unpredictable. The backend tracks all its seed changes and reveals the seed order at tournament end for post-game verification (if a player demands it).

```
# Onchain core engine system
contracts/tournament/
├── core/                          # Shared types and business logic
│   ├── TournamentCore.sol         # Core types, enums, structs
│   └── libraries/                 # Reusable logic libraries
│       ├── calculations/          # Math operations (decay, costs, prizes)
│       ├── lifecycle/             # Tournament state transitions
│       ├── player-actions/        # Join, exit, forfeit logic
│       ├── refund/                # Refund processing
│       └── views/                 # Read-only helper functions
│
├── infrastructure/                # Platform-level contracts
│   ├── deck-catalog/              # Mystery card & player objectives definitions
│   ├── factory/                   # Tournament deployment system
│   ├── registry/                  # Tournament tracking
│   └── token-whitelist/           # Approved stablecoins
│
└── modules/                       # Per-tournament game systems
    ├── hub/                       # Central state & resource management
    ├── combat/                    # Rock-paper-scissors battles
    ├── mystery-deck/              # Shared deck interactions
    ├── trading/                   # Player-to-player resource exchange
    └── randomizer/                # Pyth Entropy integration (WIP)

# Offchain core engine system
src/
├── assets/
│   ├── catalog/                   # Game content definitions
│   │   ├── cards/                 # Mystery card data
│   │   └── objectives/            # Objectives win conditions
│   ├── contracts/                 # ABIs & deployed addresses
│   └── tokens/                    # Whitelisted token info, per chain
│
├── data-structures/               # TypeScript types matching Solidity
├── features/                      # Reusable utility functions
└── parameters/                    # Deployment configuration per contract per chain

```

## Deployment flow

1. **Platform setup** (once per network, done by the platform admin):

```
   Registry ; TokenWhitelist ; DeckCatalog ; Factory
```

2. **Tournament Creation** (per game, done by the tournament creator):

```
   User -> Factory.createTournamentSystem()
     ├─ Deploy 5 minimal proxies (Hub, Combat, MysteryDeck, Trading, Randomizer)
     ├─ Initialize with game parameters
     └─ Register in Registry
```
