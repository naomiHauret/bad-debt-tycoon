/** biome-ignore-all lint/style/useNamingConvention:- */
import assert from "node:assert"
import { before, describe, test } from "node:test"
import { network } from "hardhat"
import { type Address, isAddress, type PublicActions, parseEventLogs, parseUnits } from "viem"
import { TOKEN_LIST } from "@/engine/assets/tokens/arbitrum-sepolia"
import { FORFEIT_PENALTY } from "@/engine/data-structures/forfeit"
import { TOURNAMENT_STATUS, type TournamentRules } from "@/engine/data-structures/tournament"
import FactoryModule from "@/engine/ignition/modules/FactorySystem.hardhat"

async function deployFactorySystemFixture() {
  const { ignition } = await network.connect()
  const {
    factory,
    registry,
    deckCatalog,
    whitelist,
    combatImpl,
    mysteryDeckImpl,
    tradingImpl,
    randomizerImpl,
    hubImpl,
  } = await ignition.deploy(FactoryModule)

  return {
    factory,
    registry,
    deckCatalog,
    whitelist,
    combatImpl,
    mysteryDeckImpl,
    tradingImpl,
    randomizerImpl,
    hubImpl,
  }
}

describe("Tournament Deployment", () => {
  let factory: any
  let registry: any
  let whitelist: any
  let deckCatalog: any
  let accounts: any
  let platformRunner: any
  let publicClient: PublicActions
  before(async () => {
    const { viem } = await network.connect()
    const { networkHelpers } = await network.connect()
    publicClient = await viem.getPublicClient()
    accounts = await viem.getWalletClients()
    platformRunner = accounts[0]

    const deployment = await networkHelpers.loadFixture(deployFactorySystemFixture)

    factory = deployment.factory
    registry = deployment.registry
    whitelist = deployment.whitelist
    deckCatalog = deployment.deckCatalog
  })

  describe("after factory is deployed", () => {
    test("factory should have factory role", async () => {
      const hasRole = await registry.read.hasFactoryRole([factory.address])
      assert.strictEqual(hasRole, true, "Factory must have role to register tournaments")
    })

    test("factory should be able to deploy tournaments with valid rules", async () => {
      const { networkHelpers } = await network.connect()
      const currentTime = await networkHelpers.time.latest() // need to do this to set current timestamp
      const tournamentParams: TournamentRules = {
        startTimestamp: currentTime + 10000,
        duration: 7200,
        gameInterval: 1200,
        minPlayers: 2,
        maxPlayers: 0,
        startPlayerCount: 2,
        startPoolAmount: 0,
        stakeToken: TOKEN_LIST[0].address as Address, // just need to make sure this address is in the token whitelist !
        minStake: 100,
        maxStake: 10000,
        coinConversionRate: 1,
        decayAmount: 10,
        initialLives: 3,
        cardsPerType: 5,
        exitLivesRequired: 1,
        exitCostBasePercentBPS: 5000,
        exitCostCompoundRateBPS: 1000,
        creatorFeePercent: 2,
        platformFeePercent: 1,
        forfeitAllowed: true,
        forfeitPenaltyType: FORFEIT_PENALTY.Fixed,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 20,
        deckCatalog: deckCatalog.address,
        excludedCardIds: [],
        deckDrawCost: 50,
        deckShuffleCost: 30,
        deckPeekCost: 20,
        deckOracle: "0x0000000000000000000000000000000000000456",
      }

      await factory.write.createTournamentSystem([tournamentParams], {
        account: platformRunner.account,
      })
      await factory.write.createTournamentSystem([tournamentParams], {
        account: platformRunner.account,
      })

      const registeredTournaments = await registry.read.getAllTournaments()
      assert.strictEqual(2, registeredTournaments.length, "Should have 2 tournaments")
    })

    test("factory deploy entire tournament system", async () => {
      const { networkHelpers } = await network.connect()
      const currentTime = await networkHelpers.time.latest() // need to do this to set current timestamp
      const tournamentParams: TournamentRules = {
        startTimestamp: currentTime + 10000,
        duration: 7200,
        gameInterval: 1200,
        minPlayers: 2,
        maxPlayers: 0,
        startPlayerCount: 2,
        startPoolAmount: 0,
        stakeToken: TOKEN_LIST[0].address as Address, // just need to make sure this address is in the token whitelist !
        minStake: 100,
        maxStake: 10000,
        coinConversionRate: 1,
        decayAmount: 10,
        initialLives: 3,
        cardsPerType: 5,
        exitLivesRequired: 1,
        exitCostBasePercentBPS: 5000,
        exitCostCompoundRateBPS: 1000,
        creatorFeePercent: 2,
        platformFeePercent: 1,
        forfeitAllowed: true,
        forfeitPenaltyType: FORFEIT_PENALTY.Fixed,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 20,
        deckCatalog: deckCatalog.address,
        excludedCardIds: [],
        deckDrawCost: 50,
        deckShuffleCost: 30,
        deckPeekCost: 20,
        deckOracle: "0x0000000000000000000000000000000000000456",
      }
      await factory.write.createTournamentSystem([tournamentParams], {
        account: platformRunner.account,
      })
      const tournaments = await registry.read.getAllTournaments()
      const tournament = tournaments[0]
      const deployedTournamentStatus = await registry.read.getTournamentStatus([tournament])
      assert.equal(deployedTournamentStatus, TOURNAMENT_STATUS.Open, "Tournament tracked in open tournaments")
      console.log("tournament", tournament, "factory", factory.address)
      const system = await registry.read.getTournamentSystem([tournament])
      assert.ok(isAddress(system.combat), "Combat module registered")
      assert.ok(isAddress(system.mysteryDeck), "Mystery Deck module registered")
      assert.ok(isAddress(system.trading), "Trading module registered")
      assert.ok(isAddress(system.randomizer), "Randomizer module registered")
    })
  })
})
