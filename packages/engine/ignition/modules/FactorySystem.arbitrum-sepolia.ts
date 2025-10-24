/** biome-ignore-all lint/style/noDefaultExport: -*/
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import PARAMETERS from "@/engine/contracts/params/factory/factory.arbitrum-sepolia.json"
import DeckCatalog from "./DeckCatalog"
import RegistryModule from "./Registry"
import TokenWhitelistHardhat from "./TokenWhitelist.arbitrum-sepolia"
// using parameters from the CLI didn't seem to work ?

/**
 * Tournament Factory System
 *
 * Deployment order:
 * 1. Implementation contracts (can be parallel) - these are template contracts
 * 2. Infrastructure contracts (Registry, Whitelist, DeckCatalog)
 * 3. Deploy Factory with all addresses
 * 4. Grant factory role to Factory contract in Registry
 *
 * Sidenotes :
 * - Implementation contracts are deployed once and used as templates
 * - Factory uses minimal proxies (clones) to create tournament instances
 * - Each tournament = 5 minimal proxies (Hub, Combat, MysteryDeck, Trading, Randomizer)
 * - Registry tracks all tournament systems and validates factory authorization
 */

export default buildModule("TournamentFactorySystem", (m) => {
  // Pyth Entropy configuration (required for randomness)
  const pythEntropy = PARAMETERS.TournamentFactorySystem.pythEntropy
  const entropyProvider = PARAMETERS.TournamentFactorySystem.entropyProvider
  // Admin addresses (zero address = deployer becomes admin)
  const platformAdmin = PARAMETERS.TournamentFactorySystem.platformAdmin
  const gameOracle = PARAMETERS.TournamentFactorySystem.gameOracle

  // Platform fee (max 5%)
  const platformFeePercent = PARAMETERS.TournamentFactorySystem.platformFeePercent

  // 1. Deploy module template contracts

  // These are deployed once and used as templates for minimal proxies
  // They will *NOT* be initialized - initialization happens on each clone
  const tournamentViewsLib = m.library("TournamentViews")
  const tournamentLifecyleLib = m.library("TournamentLifecycle")
  const tournamentPlayerActionsLib = m.library("TournamentPlayerActions")
  const tournamentHubPlayerLib = m.library("TournamentHubPlayer", {
    libraries: {
      TournamentPlayerActions: tournamentPlayerActionsLib,
      TournamentLifecycle: tournamentLifecyleLib,
    },
  })
  const tournamentHubPrizeLib = m.library("TournamentHubPrize", {
    libraries: {
      TournamentViews: tournamentViewsLib,
    },
  })
  const tournamentHubStatusLib = m.library("TournamentHubStatus", {
    libraries: {
      TournamentLifecycle: tournamentLifecyleLib,
      TournamentPlayerActions: tournamentPlayerActionsLib,
    },
  })
  const tournamentRefundLib = m.library("TournamentRefund")

  const hubImpl = m.contract("TournamentHub", [], {
    libraries: {
      TournamentRefund: tournamentRefundLib,
      TournamentViews: tournamentViewsLib,
      TournamentHubPlayer: tournamentHubPlayerLib,
      TournamentHubPrize: tournamentHubPrizeLib,
      TournamentHubStatus: tournamentHubStatusLib,
    },
  })
  const combatImpl = m.contract("TournamentCombat")
  const mysteryDeckImpl = m.contract("TournamentMysteryDeck")
  const tradingImpl = m.contract("TournamentTrading")
  const randomizerImpl = m.contract("TournamentRandomizer")

  // 2. Infra contracts
  // -> these should already be deployed via other modules
  const { registry } = m.useModule(RegistryModule)
  const { whitelist } = m.useModule(TokenWhitelistHardhat)
  const { catalog } = m.useModule(DeckCatalog)

  // 3. Deploy Factory
  // The factory creates tournament systems by cloning implementation contracts
  const factoryValidationLib = m.library("TournamentFactoryValidation")
  const factoryDeploymentLib = m.library("TournamentFactoryDeployment")

  const factory = m.contract(
    "TournamentFactory",
    [
      {
        hubImpl: hubImpl,
        combatImpl: combatImpl,
        mysteryDeckImpl: mysteryDeckImpl,
        tradingImpl: tradingImpl,
        randomizerImpl: randomizerImpl,
        registry: registry,
        whitelist: whitelist,
        deckCatalog: catalog,
        pythEntropy: pythEntropy,
        entropyProvider: entropyProvider,
        platformAdmin: platformAdmin,
        gameOracle: gameOracle,
        platformFeePercent: platformFeePercent,
      },
    ],
    {
      libraries: {
        TournamentFactoryDeployment: factoryDeploymentLib,
        TournamentFactoryValidation: factoryValidationLib,
      },
    },
  )

  // 4. Grant 'Factory' role to Factory contract using the registry

  // The registry must authorize the factory to register new tournament systems
  m.call(registry, "grantFactoryRole", [factory], {
    id: "grant_factory_role",
  })

  return {
    // Implementation contracts (templates)
    hubImpl,
    combatImpl,
    mysteryDeckImpl,
    tradingImpl,
    randomizerImpl,

    // Infrastructure
    registry,
    whitelist,
    deckCatalog: catalog,

    // Factory
    factory,
  }
})
