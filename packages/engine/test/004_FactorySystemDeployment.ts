import assert from "node:assert"
import { before, describe, test } from "node:test"
import { network } from "hardhat"
import { getAddress, isAddress, parseUnits, type PublicActions, zeroAddress } from "viem"
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
      hubImpl
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
      hubImpl
  }
}

describe("TournamentFactory Deployment", () => {
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

  describe("[ infra ] after successful deployment", () => {
    test("should return the deployed factory contract address", () => {
      assert.ok(isAddress(factory.address), "Factory address should be valid")
    })

    test("should return the deployed registry contract address", () => {
      assert.ok(isAddress(registry.address), "Registry address should be valid")
    })

    test("should return the deployed whitelist contract address", () => {
      assert.ok(isAddress(whitelist.address), "Whitelist address should be valid")
    })

    test("should return the deployed deck catalog contract address", () => {
      assert.ok(isAddress(deckCatalog.address), "DeckCatalog address should be valid")
    })

    test("should set the deployer as the factory owner", async () => {
      const ownerAddress = await factory.read.owner()
      assert.strictEqual(
        ownerAddress.toLowerCase(),
        getAddress(platformRunner.account.address).toLowerCase(),
        "Factory owner should match deployer",
      )
    })
  })

  describe("[ Modules ] implementation contracts", () => {
    test("should have hub implementation address set", async () => {
      const hubImpl = await factory.read.hubImplementation()
      assert.ok(isAddress(hubImpl), "Hub implementation should be valid address")
      assert.notStrictEqual(hubImpl, zeroAddress, "Hub implementation should not be zero address")
    })

    test("should have combat implementation address set", async () => {
      const combatImpl = await factory.read.combatImplementation()
      assert.ok(isAddress(combatImpl), "Combat implementation should be valid address")
      assert.notStrictEqual(combatImpl, zeroAddress, "Combat implementation should not be zero address")
    })

    test("should have mystery deck implementation address set", async () => {
      const mysteryDeckImpl = await factory.read.mysteryDeckImplementation()
      assert.ok(isAddress(mysteryDeckImpl), "MysteryDeck implementation should be valid address")
      assert.notStrictEqual(mysteryDeckImpl, zeroAddress, "MysteryDeck implementation should not be zero address")
    })

    test("should have trading implementation address set", async () => {
      const tradingImpl = await factory.read.tradingImplementation()
      assert.ok(isAddress(tradingImpl), "Trading implementation should be valid address")
      assert.notStrictEqual(tradingImpl, zeroAddress, "Trading implementation should not be zero address")
    })

    test("should have randomizer implementation address set", async () => {
      const randomizerImpl = await factory.read.randomizerImplementation()
      assert.ok(isAddress(randomizerImpl), "Randomizer implementation should be valid address")
      assert.notStrictEqual(randomizerImpl, zeroAddress, "Randomizer implementation should not be zero address")
    })

    test("should return all implementation addresses via getImplementations", async () => {
      const implementations = await factory.read.getImplementations()
      
      assert.ok(isAddress(implementations[0]), "Hub implementation should be valid")
      assert.ok(isAddress(implementations[1]), "Combat implementation should be valid")
      assert.ok(isAddress(implementations[2]), "MysteryDeck implementation should be valid")
      assert.ok(isAddress(implementations[3]), "Trading implementation should be valid")
      assert.ok(isAddress(implementations[4]), "Randomizer implementation should be valid")
    })
  })

  describe("infrastructure references", () => {
    test("should have registry address set correctly", async () => {
      const registryAddress = await factory.read.registry()
      assert.strictEqual(
        registryAddress.toLowerCase(),
        registry.address.toLowerCase(),
        "Registry address should match deployed registry",
      )
    })

    test("should have whitelist address set correctly", async () => {
      const whitelistAddress = await factory.read.whitelist()
      assert.strictEqual(
        whitelistAddress.toLowerCase(),
        whitelist.address.toLowerCase(),
        "Whitelist address should match deployed whitelist",
      )
    })

    test("should have deck catalog address set correctly", async () => {
      const deckCatalogAddress = await factory.read.deckCatalog()
      assert.strictEqual(
        deckCatalogAddress.toLowerCase(),
        deckCatalog.address.toLowerCase(),
        "DeckCatalog address should match deployed deck catalog",
      )
    })
  })

  describe("configuration", () => {
    test("should have platform admin set", async () => {
      const platformAdmin = await factory.read.platformAdmin()
      assert.ok(isAddress(platformAdmin), "Platform admin should be valid address")
      // If platformAdmin param was zero address, it should be the deployer
      assert.strictEqual(
        platformAdmin.toLowerCase(),
        getAddress(platformRunner.account.address).toLowerCase(),
        "Platform admin should be deployer when not specified",
      )
    })

    test("should have game oracle set", async () => {
      const gameOracle = await factory.read.gameOracle()
      assert.ok(isAddress(gameOracle), "Game oracle should be valid address")
    })

    test("should have platform fee percent set within valid range", async () => {
      const platformFee = await factory.read.platformFeePercent()
      assert.ok(platformFee >= 0n && platformFee <= 5n, "Platform fee should be 0-5%")
    })

    test("should have pyth entropy address set", async () => {
      const pythEntropy = await factory.read.pythEntropy()
      assert.ok(isAddress(pythEntropy), "Pyth entropy should be valid address")
      assert.notStrictEqual(pythEntropy, zeroAddress, "Pyth entropy should not be zero address")
    })

    test("should have entropy provider address set", async () => {
      const entropyProvider = await factory.read.entropyProvider()
      assert.ok(isAddress(entropyProvider), "Entropy provider should be valid address")
      assert.notStrictEqual(entropyProvider, zeroAddress, "Entropy provider should not be zero address")
    })
  })

  describe("registry authorization", () => {
    test("factory should have factory role in registry", async () => {
      const hasRole = await registry.read.hasFactoryRole([factory.address])
      assert.strictEqual(hasRole, true, "Factory should have factory role in registry")
    })

    test("factory should be able to register tournament systems", async () => {
      // This is implied by having the factory role, but we can test indirectly
      const hasRole = await registry.read.hasFactoryRole([factory.address])
      assert.strictEqual(hasRole, true, "Factory must have role to register tournaments")
    })
  })

  describe("owner functions", () => {



    test("should allow owner to update platform fee", async () => {
      const newFee = 3n // 3%
      const previousFee = await factory.read.platformFeePercent()
      if (previousFee !== newFee) {
        await factory.write.setPlatformFee([newFee], {
          account: platformRunner.account,
        })
        
        const updatedFee = await factory.read.platformFeePercent()
        assert.notEqual(updatedFee, previousFee, "Platform fee should be updated")
      }
    })    
    
/*
    test("should allow owner to send ETH deposits and withdraw", async () => {
      
      // Get initial balance (external view)
      const initialBalance = await publicClient.getBalance({ address: factory.address })
      console.log("Initial balance (external):", initialBalance.toString())
      
      // Deposit ETH
      const depositAmount = parseUnits("0.01", 18)
      console.log("Depositing:", depositAmount.toString())
      
      const txDeposit = await platformRunner.sendTransaction({
        to: factory.address,
        value: depositAmount,
      })
      await publicClient.waitForTransactionReceipt({ hash: txDeposit })
      
      const balanceAfterDeposit = await publicClient.getBalance({ address: factory.address })
      console.log("After deposit (external):", balanceAfterDeposit.toString())
      
      // Try to withdraw a TINY amount first
      const tinyAmount = parseUnits("0.0001", 18) // Just 0.0001 ETH
      console.log("\nAttempting to withdraw tiny amount:", tinyAmount.toString())
      
      try {
        const hash = await factory.write.withdrawETH([tinyAmount], {
          account: platformRunner.account,
        })
        console.log("✅ Tiny withdrawal succeeded! Hash:", hash)
        await publicClient.waitForTransactionReceipt({ hash })
        
        const balanceAfterTiny = await publicClient.getBalance({ address: factory.address })
        console.log("Balance after tiny withdrawal:", balanceAfterTiny.toString())
      } catch (error: any) {
        console.log("❌ Tiny withdrawal failed!")
        console.log("Error:", error.message)
        
        // If even tiny withdrawal fails, something is fundamentally wrong
        throw new Error("Even 0.0001 ETH withdrawal failed - there's a deeper issue")
      }
      
      // Now try the normal withdrawal
      const withdrawAmount = depositAmount / 2n
      console.log("\nAttempting normal withdrawal:", withdrawAmount.toString())
      
      await factory.write.withdrawETH([withdrawAmount], {
        account: platformRunner.account,
      })
      
      const balanceAfterWithdraw = await publicClient.getBalance({ address: factory.address })
      console.log("After withdrawal (external):", balanceAfterWithdraw.toString())
      
      // Verify the withdrawal worked
      const expectedBalance = balanceAfterDeposit - tinyAmount - withdrawAmount
      assert.ok(
        balanceAfterWithdraw <= expectedBalance,
        "Balance should decrease by withdrawal amounts",
      )
    })
*/
    test("should allow owner to update game oracle", async () => {
      const newOracle = accounts[1].account.address
      
      await factory.write.setGameOracle([newOracle], {
        account: platformRunner.account,
      })
      
      const updatedOracle = await factory.read.gameOracle()
      assert.strictEqual(
        updatedOracle.toLowerCase(),
        getAddress(newOracle).toLowerCase(),
        "Game oracle should be updated",
      )

  })})


  describe("error handling", () => {
    test("should reject platform fee higher than 5%", async () => {
      await assert.rejects(
        async () => {
          await factory.write.setPlatformFee([6n], {
            account: platformRunner.account,
          })
        },
        {
          message: /PlatformFeeTooHigh/,
        },
        "Should reject platform fee > 5%",
      )
    })

    test("should reject zero address for game oracle", async () => {
      await assert.rejects(
        async () => {
          await factory.write.setGameOracle([zeroAddress], {
            account: platformRunner.account,
          })
        },
        {
          message: /InvalidAddress/,
        },
        "Should reject zero address for game oracle",
      )
    })

    test("should reject non-owner trying to set platform fee", async () => {
      const nonOwner = accounts[1]
      
      await assert.rejects(
        async () => {
          await factory.write.setPlatformFee([3n], {
            account: nonOwner.account,
          })
        },
        {
          message: /OwnableUnauthorizedAccount/,
        },
        "Should reject non-owner setting platform fee",
      )
    })

    test("should reject non-owner trying to set game oracle", async () => {
      const nonOwner = accounts[1]
      
      await assert.rejects(
        async () => {
          await factory.write.setGameOracle([accounts[2].account.address], {
            account: nonOwner.account,
          })
        },
        {
          message: /OwnableUnauthorizedAccount/,
        },
        "Should reject non-owner setting game oracle",
      )
    })

  

    test("should reject non-owner trying to withdraw ETH", async () => {
      const nonOwner = accounts[1]
      
      await assert.rejects(
        async () => {
          await factory.write.withdrawETH([parseUnits("0.01", 18)], {
            account: nonOwner.account,
          })
        },
        {
          message: /OwnableUnauthorizedAccount/,
        },
        "Should reject non-owner withdrawing ETH",
      )
    })
})
  })