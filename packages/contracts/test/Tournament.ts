/** biome-ignore-all lint/style/useFilenamingConvention: - */
import assert from "node:assert/strict"
import { before, describe, it } from "node:test"
import { network } from "hardhat"
import { FORFEIT_PENALTY } from "./../src/components/forfeit"
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

  describe("Player actions system", () => {
    describe("Joining", () => {
      it("Should allow player to enter open tournament", async () => {
        const tournament = await deployTournament()
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })

        const balanceBefore = await token.read.balanceOf([player.account.address])

        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })

        const balanceAfter = await token.read.balanceOf([player.account.address])
        assert.equal(balanceBefore - balanceAfter, BigInt(50e18), "Stake should be transferred")

        const playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 1, "Player count should be 1")
      })

      it("Should prevent from entering non-open tournament", async () => {
        const tournament = await deployTournament({ maxPlayers: 1, startPlayerCount: 1 })
        const [, , player1, player2] = accounts

        // Player 1 joins and locks
        await token.write.mint([player1.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player1.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player1.account,
        })

        const status = await tournament.read.status()
        assert.equal(status, TOURNAMENT_STATUS.Locked, "Should be Locked")

        // Player 2 tries to join locked tournament
        await token.write.mint([player2.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player2.account,
        })

        await assert.rejects(
          async () => {
            await tournament.write.joinTournament([BigInt(50e18)], {
              account: player2.account,
            })
          },
          /InvalidStatus/,
          "Should revert when trying to join non-open tournament",
        )
      })

      it("Should prevent player from joining without required stake", async () => {
        const tournament = await deployTournament({ minStake: BigInt(50e18) })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(30e18)], {
          account: player.account,
        })

        await assert.rejects(
          async () => {
            await tournament.write.joinTournament([BigInt(30e18)], {
              account: player.account,
            })
          },
          /StakeTooLow/,
          "Should revert when stake is below minimum",
        )
      })
    })

    describe("Withdrawing", () => {
      it("should let player withdraw before tournament starts and get their stake back fully", async () => {
        const tournament = await deployTournament()
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })

        const balanceBefore = await token.read.balanceOf([player.account.address])

        await tournament.write.claimRefund({ account: player.account })

        const balanceAfter = await token.read.balanceOf([player.account.address])
        assert.equal(balanceAfter - balanceBefore, BigInt(50e18), "Should get full stake back")

        const playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 0, "Player count should be 0 after withdrawal")
      })

      it("should allow player to enter/withdraw back and forth while tournament is opened", async () => {
        const tournament = await deployTournament()
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(300e18)])

        // Join
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })
        let playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 1)

        // Withdraw
        await tournament.write.claimRefund({ account: player.account })
        playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 0)

        // Join again
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })
        playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 1)

        // Withdraw again
        await tournament.write.claimRefund({ account: player.account })
        playerCount = await tournament.read.playerCount()
        assert.equal(playerCount, 0, "Should be able to join/withdraw multiple times")
      })

      it("should not be possible after tournament starts", async () => {
        const tournament = await deployTournament({ startPlayerCount: 1 })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })

        // Start tournament
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        const status = await tournament.read.status()
        assert.equal(status, TOURNAMENT_STATUS.Active, "Should be Active")

        await assert.rejects(
          async () => {
            await tournament.write.claimRefund({ account: player.account })
          },
          /CannotRefundAfterStart/,
          "Should not allow refund after tournament starts",
        )
      })

      it("should only claim player's stake", async () => {
        const tournament = await deployTournament()
        const [, , player1, player2] = accounts

        // Both players join
        await token.write.mint([player1.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(30e18)], {
          account: player1.account,
        })
        await tournament.write.joinTournament([BigInt(30e18)], {
          account: player1.account,
        })

        await token.write.mint([player2.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(70e18)], {
          account: player2.account,
        })
        await tournament.write.joinTournament([BigInt(70e18)], {
          account: player2.account,
        })

        // Player 1 withdraws
        const balanceBefore = await token.read.balanceOf([player1.account.address])
        await tournament.write.claimRefund({ account: player1.account })
        const balanceAfter = await token.read.balanceOf([player1.account.address])

        assert.equal(balanceAfter - balanceBefore, BigInt(30e18), "Should only get their own stake, not others'")
      })
    })

    describe("Forfeiting", () => {
      it("Fixed penalty should slash the player's stake with a fixed % (same for all players)", async () => {
        const tournament = await deployTournament({
          startPlayerCount: 1,
          forfeitPenaltyType: FORFEIT_PENALTY.Fixed,
          forfeitMaxPenalty: 50, // 50% fixed
          forfeitMinPenalty: 50,
        })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(100e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(100e18)], {
          account: player.account,
        })

        // Start tournament
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        const balanceBefore = await token.read.balanceOf([player.account.address])

        await tournament.write.forfeit({ account: player.account })

        const balanceAfter = await token.read.balanceOf([player.account.address])
        const refund = balanceAfter - balanceBefore

        // Should get 50% back (50 tokens)
        assert.equal(refund, BigInt(50e18), "Should receive 50% refund with fixed penalty")
      })

      it("Time based penalty should slash the player's stake with an escalating % (varies on forfeiting timestamp)", async () => {
        const tournament = await deployTournament({
          startPlayerCount: 1,
          duration: 1000,
          forfeitPenaltyType: FORFEIT_PENALTY.TimeBased, // TimeRemaining
          forfeitMaxPenalty: 80,
          forfeitMinPenalty: 10,
        })
        const [, , player1, player2] = accounts

        // Player 1 joins
        await token.write.mint([player1.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(100e18)], {
          account: player1.account,
        })
        await tournament.write.joinTournament([BigInt(100e18)], {
          account: player1.account,
        })

        // Start tournament
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        // Player 1 forfeits early (high penalty)
        const balance1Before = await token.read.balanceOf([player1.account.address])
        await tournament.write.forfeit({ account: player1.account })
        const balance1After = await token.read.balanceOf([player1.account.address])
        const refund1 = balance1After - balance1Before

        // Deploy new tournament for player 2
        const tournament2 = await deployTournament({
          startPlayerCount: 1,
          duration: 1000,
          forfeitPenaltyType: FORFEIT_PENALTY.TimeBased,
          forfeitMaxPenalty: 80,
          forfeitMinPenalty: 10,
        })

        await token.write.mint([player2.account.address, BigInt(100e18)])
        await token.write.approve([tournament2.address, BigInt(100e18)], {
          account: player2.account,
        })
        await tournament2.write.joinTournament([BigInt(100e18)], {
          account: player2.account,
        })

        // Start
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament2.write.updateStatus()

        // Wait most of the duration
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [900],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })

        // Player 2 forfeits late (lower penalty)
        const balance2Before = await token.read.balanceOf([player2.account.address])
        await tournament2.write.forfeit({ account: player2.account })
        const balance2After = await token.read.balanceOf([player2.account.address])
        const refund2 = balance2After - balance2Before

        console.log("Early forfeit refund:", refund1)
        console.log("Late forfeit refund:", refund2)

        assert.ok(refund2 > refund1, "Late forfeit should get more refund than early forfeit")
      })

      it("Time based penalty % should stay within defined bounds", async () => {
        const tournament = await deployTournament({
          startPlayerCount: 1,
          duration: 1000,
          forfeitPenaltyType: FORFEIT_PENALTY.TimeBased,
          forfeitMaxPenalty: 80, // Max 80% penalty
          forfeitMinPenalty: 10, // Min 10% penalty
        })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(100e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(100e18)], {
          account: player.account,
        })

        // Start
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        // Forfeit immediately (should get min penalty = 10%, so 90 tokens back)
        const balanceBefore = await token.read.balanceOf([player.account.address])
        await tournament.write.forfeit({ account: player.account })
        const balanceAfter = await token.read.balanceOf([player.account.address])
        const refund = balanceAfter - balanceBefore

        // Should get at least 20% back (100 - 80 max penalty)
        assert.ok(refund >= BigInt(20e18), "Refund should be at least 20% (max 80% penalty)")
        // Should get at most 90% back (100 - 10 min penalty)
        assert.ok(refund <= BigInt(90e18), "Refund should be at most 90% (min 10% penalty)")
      })
    })

    describe("Exiting", () => {
      it("should allow player to exit when conditions met", async () => {
        const tournament = await deployTournament({
          startPlayerCount: 1,
          exitLivesRequired: 5,
          initialLives: 5,
        })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })

        // Start tournament
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        // Exit
        await tournament.write.exit({ account: player.account })

        const winners = await tournament.read.getWinners()
        assert.equal(winners.length, 1, "Should have 1 winner")
        assert.equal(winners[0].toUpperCase(), player.account.address.toUpperCase(), "Player should be winner")
      })

      it("should not allow player to exit when conditions are not met", async () => {
        const tournament = await deployTournament({
          startPlayerCount: 1,
          exitLivesRequired: 10,
          initialLives: 5, // Not enough lives
        })
        const player = accounts[2]

        await token.write.mint([player.account.address, BigInt(100e18)])
        await token.write.approve([tournament.address, BigInt(50e18)], {
          account: player.account,
        })
        await tournament.write.joinTournament([BigInt(50e18)], {
          account: player.account,
        })

        // Start tournament
        await publicClient.transport.request({
          method: "evm_increaseTime" as any,
          params: [110],
        })
        await publicClient.transport.request({
          method: "evm_mine" as any,
          params: [],
        })
        await tournament.write.updateStatus()

        await assert.rejects(
          async () => {
            await tournament.write.exit({ account: player.account })
          },
          /CannotExit/,
          "Should not allow exit when conditions not met",
        )
      })
    })
  })

  describe("Prize distribution", () => {
    it("should allow winners to claim equal share of prize after tournament ends", async () => {
      const tournament = await deployTournament({
        startPlayerCount: 2,
        maxPlayers: 2,
        duration: 100,
      })
      const [, creator, player1, player2] = accounts

      // Both join with 100 tokens (200 total)
      await token.write.mint([player1.account.address, BigInt(200e18)])
      await token.write.mint([player2.account.address, BigInt(200e18)])

      await token.write.approve([tournament.address, BigInt(100e18)], {
        account: player1.account,
      })
      await tournament.write.joinTournament([BigInt(100e18)], {
        account: player1.account,
      })

      await token.write.approve([tournament.address, BigInt(100e18)], {
        account: player2.account,
      })
      await tournament.write.joinTournament([BigInt(100e18)], {
        account: player2.account,
      })

      // Start
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Both exit
      await tournament.write.exit({ account: player1.account })
      await tournament.write.exit({ account: player2.account })

      // End tournament
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Claim prizes
      // Total: 200, Platform fee (1%): 2, Creator fee (2%): 4
      // Remaining: 194, Per winner: 97
      const balance1Before = await token.read.balanceOf([player1.account.address])
      await tournament.write.claimPrize({ account: player1.account })
      const balance1After = await token.read.balanceOf([player1.account.address])

      const balance2Before = await token.read.balanceOf([player2.account.address])
      await tournament.write.claimPrize({ account: player2.account })
      const balance2After = await token.read.balanceOf([player2.account.address])

      const prize1 = balance1After - balance1Before
      const prize2 = balance2After - balance2Before

      assert.equal(prize1, prize2, "Both winners should get equal prize")
      assert.equal(prize1, BigInt(97e18), "Each should get 97 tokens")
    })

    it("should only allow winner to collect prize share once", async () => {
      const tournament = await deployTournament({
        startPlayerCount: 1,
        duration: 100,
      })
      const player = accounts[2]

      await token.write.mint([player.account.address, BigInt(100e18)])
      await token.write.approve([tournament.address, BigInt(50e18)], {
        account: player.account,
      })
      await tournament.write.joinTournament([BigInt(50e18)], {
        account: player.account,
      })

      // Start and exit
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()
      await tournament.write.exit({ account: player.account })

      // End
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Claim once
      await tournament.write.claimPrize({ account: player.account })

      // Try claim again
      await assert.rejects(
        async () => {
          await tournament.write.claimPrize({ account: player.account })
        },
        /AlreadyClaimed/,
        "Should not allow claiming twice",
      )
    })

    it("should allow winners to collect at anytime after the tournament ended", async () => {
      const tournament = await deployTournament({
        startPlayerCount: 1,
        duration: 100,
      })
      const player = accounts[2]

      await token.write.mint([player.account.address, BigInt(100e18)])
      await token.write.approve([tournament.address, BigInt(50e18)], {
        account: player.account,
      })
      await tournament.write.joinTournament([BigInt(50e18)], {
        account: player.account,
      })

      // Start and exit
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()
      await tournament.write.exit({ account: player.account })

      // End
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Wait a long time
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [100000],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })

      // Should still be able to claim
      const balanceBefore = await token.read.balanceOf([player.account.address])
      await tournament.write.claimPrize({ account: player.account })
      const balanceAfter = await token.read.balanceOf([player.account.address])

      assert.ok(balanceAfter > balanceBefore, "Should receive prize even after long time")
    })

    it("should not allow losers/forfeited/withdrawn to collect from the prize pool", async () => {
      const tournament = await deployTournament({
        startPlayerCount: 1,
      })
      const player = accounts[2]

      await token.write.mint([player.account.address, BigInt(100e18)])
      await token.write.approve([tournament.address, BigInt(50e18)], {
        account: player.account,
      })
      await tournament.write.joinTournament([BigInt(50e18)], {
        account: player.account,
      })

      // Start and forfeit
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()
      await tournament.write.forfeit({ account: player.account })

      // End
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [3710],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Try to claim prize
      await assert.rejects(
        async () => {
          await tournament.write.claimPrize({ account: player.account })
        },
        /NotWinner/,
        "Forfeited player should not be able to claim prize",
      )
    })
  })

  describe("Fee collection", () => {
    it("should allow creator to collect fees after tournament ends", async () => {
      const tournament = await deployTournament({
        startPlayerCount: 1,
        duration: 100,
        creatorFeePercent: 5,
      })
      const [, creator] = accounts
      const player = accounts[2]

      await token.write.mint([player.account.address, BigInt(100e18)])
      await token.write.approve([tournament.address, BigInt(100e18)], {
        account: player.account,
      })
      await tournament.write.joinTournament([BigInt(100e18)], {
        account: player.account,
      })

      // Start and exit
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()
      await tournament.write.exit({ account: player.account })

      // End
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Creator collects (5% of 100 = 5)
      const balanceBefore = await token.read.balanceOf([creator.account.address])
      await tournament.write.collectCreatorFees({ account: creator.account })
      const balanceAfter = await token.read.balanceOf([creator.account.address])

      const creatorFee = balanceAfter - balanceBefore
      assert.equal(creatorFee, BigInt(5e18), "Creator should receive 5% fee")
    })

    it("should allow platform to collect fees after tournament ends", async () => {
      // Note: Platform fees are collected via TournamentFactory, not individual tournaments
      // This test demonstrates the calculation is correct in the prize distribution
      const tournament = await deployTournament({
        startPlayerCount: 2,
        duration: 100,
        platformFeePercent: 3,
        creatorFeePercent: 2,
      })
      const [, , player1, player2] = accounts

      // Both join with 100 tokens (200 total)
      await token.write.mint([player1.account.address, BigInt(200e18)])
      await token.write.mint([player2.account.address, BigInt(200e18)])

      await token.write.approve([tournament.address, BigInt(100e18)], {
        account: player1.account,
      })
      await tournament.write.joinTournament([BigInt(100e18)], {
        account: player1.account,
      })

      await token.write.approve([tournament.address, BigInt(100e18)], {
        account: player2.account,
      })
      await tournament.write.joinTournament([BigInt(100e18)], {
        account: player2.account,
      })

      // Start and both exit
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()
      await tournament.write.exit({ account: player1.account })
      await tournament.write.exit({ account: player2.account })

      // End
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await tournament.write.updateStatus()

      // Check tournament balance includes platform fees
      const tournamentBalance = await token.read.balanceOf([tournament.address])

      // Total: 200
      // Platform fee (3%): 6
      // Creator fee (2%): 4
      // To winners: 190 (95 each)
      // Tournament should hold: 6 (platform fee) + 4 (uncollected creator fee) = 10

      console.log("Tournament balance before any claims:", tournamentBalance)

      // Player 1 claims
      const balance1Before = await token.read.balanceOf([player1.account.address])
      await tournament.write.claimPrize({ account: player1.account })
      const balance1After = await token.read.balanceOf([player1.account.address])
      const prize1 = balance1After - balance1Before // Calculate the prize received

      assert.equal(prize1, BigInt(95e18), "Each winner gets 95 tokens (200 - 3% - 2% = 190, split 2 ways)")

      // Verify platform fee is held in contract
      const finalTournamentBalance = await token.read.balanceOf([tournament.address])
      console.log("Tournament balance after player1 claims:", finalTournamentBalance)

      // Should have: platform fee (6) + creator fee (4) + player2 unclaimed prize (95) = 105
      assert.equal(finalTournamentBalance, BigInt(105e18), "Platform fee should remain in contract")
    })
  })

  describe("[complete flow]", () => {
    it("should complete full tournament flow with status transitions, with prize distribution", async () => {
      const [platformAdmin, creator, player1, player2] = accounts

      // Deploy fresh tournament
      const fullFlowTournament = await viem.deployContract("Tournament", [], {
        libraries: {
          TournamentLifecycle: lifecycleLib.address,
          TournamentPlayerActions: playerActionsLib.address,
          TournamentRefund: refundLib.address,
          TournamentViews: viewsLib.address,
        },
      })

      await registry.write.registerTournament([fullFlowTournament.address], {
        account: platformAdmin.account,
      })
      let status = await fullFlowTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Open, "Should be Open")

      const block = await publicClient.getBlock()
      const currentTime = Number(block.timestamp)

      const params = {
        stakeToken: token.address,
        minStake: BigInt(10e18),
        maxStake: BigInt(1000e18),
        minPlayers: 2,
        maxPlayers: 2,
        startTimestamp: currentTime + 50,
        duration: 100, // Short duration
        startPlayerCount: 2,
        startPoolAmount: 0n,
        platformFeePercent: 1,
        creatorFeePercent: 2,
        coinConversionRate: 100,
        initialLives: 3,
        cardsPerType: 0, // No cards needed for exit
        exitLivesRequired: 3,
        decayAmount: 0, // No decay
        decayInterval: 3600,
        exitCostBasePercentBPS: 0, // No exit cost
        exitCostCompoundRateBPS: 0,
        exitCostInterval: 3600,
        forfeitAllowed: true,
        forfeitPenaltyType: 0,
        forfeitMaxPenalty: 80,
        forfeitMinPenalty: 10,
      }

      await fullFlowTournament.write.initialize([
        params,
        creator.account.address,
        registry.address,
        whitelist.address,
        platformAdmin.account.address,
      ])

      // 2 players join with 100 tokens each (200 total)
      await token.write.mint([player1.account.address, BigInt(200e18)])
      await token.write.mint([player2.account.address, BigInt(200e18)])

      await token.write.approve([fullFlowTournament.address, BigInt(100e18)], {
        account: player1.account,
      })
      await fullFlowTournament.write.joinTournament([BigInt(100e18)], {
        account: player1.account,
      })

      await token.write.approve([fullFlowTournament.address, BigInt(100e18)], {
        account: player2.account,
      })
      await fullFlowTournament.write.joinTournament([BigInt(100e18)], {
        account: player2.account,
      })

      // Start tournament
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [60],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await fullFlowTournament.write.updateStatus()

      status = await fullFlowTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Active, "Should be Active")

      // Both players exit (become winners)
      await fullFlowTournament.write.exit({ account: player1.account })
      await fullFlowTournament.write.exit({ account: player2.account })

      // End tournament (time passes)
      await publicClient.transport.request({
        method: "evm_increaseTime" as any,
        params: [110],
      })
      await publicClient.transport.request({
        method: "evm_mine" as any,
        params: [],
      })
      await fullFlowTournament.write.updateStatus()

      status = await fullFlowTournament.read.status()
      assert.equal(status, TOURNAMENT_STATUS.Ended, "Should be Ended")

      const creatorBalanceBefore = await token.read.balanceOf([creator.account.address])
      await fullFlowTournament.write.collectCreatorFees({ account: creator.account })
      const creatorBalanceAfter = await token.read.balanceOf([creator.account.address])
      const creatorFee = creatorBalanceAfter - creatorBalanceBefore

      assert.equal(creatorFee, BigInt(4e18), "Creator should receive 2% (4 tokens)")

      // Winners claim prizes
      // Total pool: 200 tokens
      // Platform fee (1%): 2 tokens
      // Creator fee (2%): 4 tokens
      // Remaining for winners: 194 tokens
      // Per winner (2 winners): 97 tokens each

      const player1BalanceBefore = await token.read.balanceOf([player1.account.address])
      await fullFlowTournament.write.claimPrize({ account: player1.account })
      const player1BalanceAfter = await token.read.balanceOf([player1.account.address])
      const player1Prize = player1BalanceAfter - player1BalanceBefore

      const player2BalanceBefore = await token.read.balanceOf([player2.account.address])
      await fullFlowTournament.write.claimPrize({ account: player2.account })
      const player2BalanceAfter = await token.read.balanceOf([player2.account.address])
      const player2Prize = player2BalanceAfter - player2BalanceBefore

      console.log("Player 1 prize:", player1Prize)
      console.log("Player 2 prize:", player2Prize)

      // Each should get 97 tokens (194 / 2)
      const expectedPrize = BigInt(97e18)
      assert.equal(player1Prize, expectedPrize, "Player 1 should receive correct prize")
      assert.equal(player2Prize, expectedPrize, "Player 2 should receive correct prize")
    })
  })
})
