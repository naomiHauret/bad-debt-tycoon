/** biome-ignore-all lint/style/useFilenamingConvention: - */
import assert from "node:assert/strict"
import { before, describe, it } from "node:test"
import { network } from "hardhat"
import { TOURNAMENT_STATUS } from "./../src/components/tournament"

describe("Tournament Lifecycle", async () => {
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

  describe("Status transitions", () => {
    it("should transition from Open to Locked when max players reached", async () => {
      const [platformAdmin, creator] = accounts

      // Deploy tournament with low maxPlayers
      const lockedTournament = await viem.deployContract("Tournament", [], {
        libraries: {
          TournamentLifecycle: lifecycleLib.address,
          TournamentPlayerActions: playerActionsLib.address,
          TournamentRefund: refundLib.address,
          TournamentViews: viewsLib.address,
        },
      })

      await registry.write.registerTournament([lockedTournament.address], {
        account: platformAdmin.account,
      })

      const block = await publicClient.getBlock()
      const currentTime = Number(block.timestamp)

      const params = {
        stakeToken: token.address,
        minStake: BigInt(10e18),
        maxStake: BigInt(1000e18),
        minPlayers: 2,
        maxPlayers: 2, // Lock after 2 players
        startTimestamp: currentTime + 200,
        duration: 3600,
        startPlayerCount: 2,
        startPoolAmount: 0n,
        platformFeePercent: 1,
        creatorFeePercent: 2,
        coinConversionRate: 100,
        initialLives: 5,
        cardsPerType: 10,
        exitLivesRequired: 3,
        decayAmount: 5,
        decayInterval: 3600,
        exitCostBasePercentBPS: 10000,
        exitCostCompoundRateBPS: 1000,
        exitCostInterval: 3600,
        forfeitAllowed: true,
        forfeitPenaltyType: 0,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 10,
      }

      await lockedTournament.write.initialize([
        params,
        creator.account.address,
        registry.address,
        whitelist.address,
        platformAdmin.account.address,
      ])

      const [, , player1, player2] = accounts

      // Mint and player 1 joins
      await token.write.mint([player1.account.address, BigInt(100e18)])
      await token.write.approve([lockedTournament.address, BigInt(50e18)], {
        account: player1.account,
      })
      await lockedTournament.write.joinTournament([BigInt(50e18)], {
        account: player1.account,
      })

      let status = await lockedTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Open, "Should be Open with 1 player")

      // Player 2 joins - should trigger lock
      await token.write.mint([player2.account.address, BigInt(100e18)])
      await token.write.approve([lockedTournament.address, BigInt(50e18)], {
        account: player2.account,
      })
      await lockedTournament.write.joinTournament([BigInt(50e18)], {
        account: player2.account,
      })

      status = await lockedTournament.read.status()
      console.log("Status after reaching maxPlayers:", status)
      assert.equal(status, TOURNAMENT_STATUS.Locked, "Should be Locked when maxPlayers reached")

      // Fast forward and verify it still transitions to Active
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [200],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })

      await lockedTournament.write.updateStatus()

      status = await lockedTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Active, "Should transition from Locked to Active")
    })

    it("should handle multiple start conditions (player count + pool amount)", async () => {
      const [platformAdmin, creator] = accounts

      const multiConditionTournament = await viem.deployContract("Tournament", [], {
        libraries: {
          TournamentLifecycle: lifecycleLib.address,
          TournamentPlayerActions: playerActionsLib.address,
          TournamentRefund: refundLib.address,
          TournamentViews: viewsLib.address,
        },
      })

      await registry.write.registerTournament([multiConditionTournament.address], {
        account: platformAdmin.account,
      })

      const block = await publicClient.getBlock()
      const currentTime = Number(block.timestamp)

      const params = {
        stakeToken: token.address,
        minStake: BigInt(10e18),
        maxStake: BigInt(1000e18),
        minPlayers: 2,
        maxPlayers: 0,
        startTimestamp: currentTime + 50,
        duration: 3600,
        startPlayerCount: 2, // Need at least 2 players
        startPoolAmount: BigInt(80e18), // Need at least 80 tokens
        platformFeePercent: 1,
        creatorFeePercent: 2,
        coinConversionRate: 100,
        initialLives: 5,
        cardsPerType: 10,
        exitLivesRequired: 3,
        decayAmount: 5,
        decayInterval: 3600,
        exitCostBasePercentBPS: 10000,
        exitCostCompoundRateBPS: 1000,
        exitCostInterval: 3600,
        forfeitAllowed: true,
        forfeitPenaltyType: 0,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 10,
      }

      await multiConditionTournament.write.initialize([
        params,
        creator.account.address,
        registry.address,
        whitelist.address,
        platformAdmin.account.address,
      ])

      const [, , player1, player2] = accounts

      // Player 1 joins with 30 (not enough pool amount yet)
      await token.write.mint([player1.account.address, BigInt(100e18)])
      await token.write.approve([multiConditionTournament.address, BigInt(30e18)], {
        account: player1.account,
      })
      await multiConditionTournament.write.joinTournament([BigInt(30e18)], {
        account: player1.account,
      })

      // Player 2 joins with 30 (total = 60, still not enough)
      await token.write.mint([player2.account.address, BigInt(100e18)])
      await token.write.approve([multiConditionTournament.address, BigInt(30e18)], {
        account: player2.account,
      })
      await multiConditionTournament.write.joinTournament([BigInt(30e18)], {
        account: player2.account,
      })

      // Time travel past start time
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [60],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })

      // Update status - should cancel (player count met, but pool amount not met)
      await multiConditionTournament.write.updateStatus()

      let status = await multiConditionTournament.read.status()
      console.log("Status with 2 players but insufficient pool:", status)
      assert.equal(status, TOURNAMENT_STATUS.Cancelled, "Should be Cancelled when pool amount requirement not met")

      // Now test with BOTH conditions met
      const successTournament = await viem.deployContract("Tournament", [], {
        libraries: {
          TournamentLifecycle: lifecycleLib.address,
          TournamentPlayerActions: playerActionsLib.address,
          TournamentRefund: refundLib.address,
          TournamentViews: viewsLib.address,
        },
      })

      await registry.write.registerTournament([successTournament.address], {
        account: platformAdmin.account,
      })

      const block2 = await publicClient.getBlock()
      const currentTime2 = Number(block2.timestamp)

      await successTournament.write.initialize([
        {
          ...params,
          startTimestamp: currentTime2 + 50,
        },
        creator.account.address,
        registry.address,
        whitelist.address,
        platformAdmin.account.address,
      ])

      // Player 1 joins with 50 (enough!)
      const player3 = accounts[5]
      const player4 = accounts[6]
      await token.write.mint([player3.account.address, BigInt(100e18)])
      await token.write.approve([successTournament.address, BigInt(50e18)], {
        account: player3.account,
      })
      await successTournament.write.joinTournament([BigInt(50e18)], {
        account: player3.account,
      })

      // Player 2 joins with 50 (total = 100, enough!)
      await token.write.mint([player4.account.address, BigInt(100e18)])
      await token.write.approve([successTournament.address, BigInt(50e18)], {
        account: player4.account,
      })
      await successTournament.write.joinTournament([BigInt(50e18)], {
        account: player4.account,
      })

      // Time travel
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [60],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })

      // Update status - should succeed (both conditions met)
      await successTournament.write.updateStatus()

      status = await successTournament.read.status()
      console.log("Status with both conditions met:", status)
      assert.equal(status, TOURNAMENT_STATUS.Active, "Should be Active when both player count and pool amount met")
    })

    it("should unlock tournament when player withdraws from Locked state", async () => {
      const [platformAdmin, creator] = accounts

      // Deploy tournament with maxPlyers that will lock
      const unlockTournament = await viem.deployContract("Tournament", [], {
        libraries: {
          TournamentLifecycle: lifecycleLib.address,
          TournamentPlayerActions: playerActionsLib.address,
          TournamentRefund: refundLib.address,
          TournamentViews: viewsLib.address,
        },
      })

      await registry.write.registerTournament([unlockTournament.address], {
        account: platformAdmin.account,
      })

      const block = await publicClient.getBlock()
      const currentTime = Number(block.timestamp)

      const params = {
        stakeToken: token.address,
        minStake: BigInt(10e18),
        maxStake: BigInt(1000e18),
        minPlayers: 2,
        maxPlayers: 3, // Lock after 3 players
        startTimestamp: currentTime + 300, // Far in future (so we can test refund)
        duration: 3600,
        startPlayerCount: 3,
        startPoolAmount: 0n,
        platformFeePercent: 1,
        creatorFeePercent: 2,
        coinConversionRate: 100,
        initialLives: 5,
        cardsPerType: 10,
        exitLivesRequired: 3,
        decayAmount: 5,
        decayInterval: 3600,
        exitCostBasePercentBPS: 10000,
        exitCostCompoundRateBPS: 1000,
        exitCostInterval: 3600,
        forfeitAllowed: true,
        forfeitPenaltyType: 0,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 10,
      }

      await unlockTournament.write.initialize([
        params,
        creator.account.address,
        registry.address,
        whitelist.address,
        platformAdmin.account.address,
      ])

      const player5 = accounts[7]
      const player6 = accounts[8]
      const player7 = accounts[9]

      // Player 5 joins (n°1)
      await token.write.mint([player5.account.address, BigInt(100e18)])
      await token.write.approve([unlockTournament.address, BigInt(50e18)], {
        account: player5.account,
      })
      await unlockTournament.write.joinTournament([BigInt(50e18)], {
        account: player5.account,
      })

      let status = await unlockTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Open, "Should be Open with 1 player")

      // Player 6 joins (n°2)
      await token.write.mint([player6.account.address, BigInt(100e18)])
      await token.write.approve([unlockTournament.address, BigInt(50e18)], {
        account: player6.account,
      })
      await unlockTournament.write.joinTournament([BigInt(50e18)], {
        account: player6.account,
      })

      status = await unlockTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Open, "Should still be Open with 2 players")

      // Player 7 joins - should trigger lock (maxPlayers = 3) (n°3)
      const player7InitialBalance = BigInt(100e18)
      await token.write.mint([player7.account.address, player7InitialBalance])
      await token.write.approve([unlockTournament.address, BigInt(50e18)], {
        account: player7.account,
      })
      await unlockTournament.write.joinTournament([BigInt(50e18)], {
        account: player7.account,
      })

      status = await unlockTournament.read.status()
      console.log("Status after 3 players (maxPlayers reached):", status)
      assert.equal(status, TOURNAMENT_STATUS.Locked, "Should be Locked with 3 players")

      // Player 7 withdraws (claims refund) - should unlock
      const playerCountBefore = await unlockTournament.read.playerCount()
      const balanceBefore = await token.read.balanceOf([player7.account.address])
      console.log("Player 7 balance before refund:", balanceBefore)

      await unlockTournament.write.claimRefund({
        account: player7.account,
      })

      const balanceAfter = await token.read.balanceOf([player7.account.address])
      console.log("Player 7 balance after refund:", balanceAfter)
      assert.equal(balanceAfter, player7InitialBalance, "Player should receive full refund")

      status = await unlockTournament.read.status()
      console.log("Status after player withdrawal from Locked:", status)
      assert.equal(status, TOURNAMENT_STATUS.Open, "Should be Open again after dropping below maxPlayers")

      // Verify player count decreased
      const playerCountAfter = await unlockTournament.read.playerCount()
      assert.equal(playerCountAfter, playerCountBefore - 1, "Player count should decrease by 1 after withdrawal")
    })
  })

})
