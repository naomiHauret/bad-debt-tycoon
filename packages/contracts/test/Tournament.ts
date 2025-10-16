/** biome-ignore-all lint/style/useFilenamingConvention: - */
import { before, describe } from "node:test"
import { network } from "hardhat"

describe("Tournament", async () => {
  const { viem } = await network.connect()
  const publicClient = await viem.getPublicClient()

  let token: any
  let registry: any
  let whitelist: any
  let accounts: any
  let lifecycleLib: any
  let playerActionsLib: any
  let refundLib: any
  let viewsLib: any

  before(async () => {
    accounts = await viem.getWalletClients()
    const [platformAdmin] = accounts

    // Deploy token
    token = await viem.deployContract("MockERC20", ["PayPal USD", "PYUSD", 6])

    // Deploy registry
    registry = await viem.deployContract("TournamentRegistry", [], {
      client: { wallet: platformAdmin },
    })

    // Deploy whitelist
    whitelist = await viem.deployContract("TournamentTokenWhitelist", [platformAdmin.account.address], {
      client: { wallet: platformAdmin },
    })

    // Whitelist token
    await whitelist.write.addToken([token.address], {
      account: platformAdmin.account,
    })

    // Grant factory role to platformAdmin
    await registry.write.grantFactoryRole([platformAdmin.account.address], {
      account: platformAdmin.account,
    })

    // Deploy libraries
    console.log("Deploying libraries...")
    lifecycleLib = await viem.deployContract("TournamentLifecycle", [])
    playerActionsLib = await viem.deployContract("TournamentPlayerActions", [])
    refundLib = await viem.deployContract("TournamentRefund", [])
    viewsLib = await viem.deployContract("TournamentViews", [])
    console.log("Libraries deployed\n")
  })

  // Helper to deploy a fresh tournament
  async function deployTournament(customParams = {}) {
    const [platformAdmin, creator] = accounts

    const tournament = await viem.deployContract("Tournament", [], {
      libraries: {
        TournamentLifecycle: lifecycleLib.address,
        TournamentPlayerActions: playerActionsLib.address,
        TournamentRefund: refundLib.address,
        TournamentViews: viewsLib.address,
      },
    })

    await registry.write.registerTournament([tournament.address], {
      account: platformAdmin.account,
    })

    const block = await publicClient.getBlock()
    const currentTime = Number(block.timestamp)

    const defaultParams = {
      stakeToken: token.address,
      minStake: BigInt(10e18),
      maxStake: BigInt(1000e18),
      minPlayers: 1,
      maxPlayers: 0,
      startTimestamp: currentTime + 100,
      duration: 3600,
      startPlayerCount: 2,
      startPoolAmount: 0n,
      platformFeePercent: 1,
      creatorFeePercent: 2,
      coinConversionRate: 100,
      initialLives: 5,
      cardsPerType: 0, // No cards for easy testing
      exitLivesRequired: 3,
      decayAmount: 0, // No decay for easy testing
      decayInterval: 3600,
      exitCostBasePercentBPS: 0, // No exit cost
      exitCostCompoundRateBPS: 0,
      exitCostInterval: 3600,
      forfeitAllowed: true,
      forfeitPenaltyType: 0,
      forfeitMaxPenalty: 80,
      forfeitMinPenalty: 10,
      ...customParams,
    }

    await tournament.write.initialize([
      defaultParams,
      creator.account.address,
      registry.address,
      whitelist.address,
      platformAdmin.account.address,
    ])

    return tournament
  }
})
