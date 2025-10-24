import assert from "node:assert"
import { before, describe, test } from "node:test"
import { network } from "hardhat"
import { getAddress, isAddress } from "viem"
import { TOKEN_LIST } from "@/engine/assets/tokens/arbitrum-sepolia" // yes, i know, let me cook
import TokenWhitelistModule from "@/engine/ignition/modules/TokenWhitelist.hardhat"

async function deployTokenWhitelistFixture() {
  const { ignition } = await network.connect()
  return ignition.deploy(TokenWhitelistModule)
}

describe("TournamentTokenWhitelist Deployment", () => {
  let tokenWhitelistInstance: any
  let accounts: any
  let platformRunner: any

  before(async () => {
    const { viem } = await network.connect()

    const { networkHelpers } = await network.connect()
    accounts = await viem.getWalletClients()
    platformRunner = accounts[0]
    const { whitelist } = await networkHelpers.loadFixture(deployTokenWhitelistFixture)
    tokenWhitelistInstance = whitelist
  })

  describe("after successful deployment", () => {
    test("should return the deployed contract address", () => {
      assert.ok(isAddress(tokenWhitelistInstance.address), "Contract address should be valid")
    })

    test("should set the deployer as the platform runner", async () => {
      const ownerAddress = await tokenWhitelistInstance.read.owner()
      assert.strictEqual(
        ownerAddress.toLowerCase(),
        getAddress(platformRunner.account.address).toLowerCase(),
        "Owner should match deployer",
      )
    })

    test("should have tokens from static list whitelisted", async () => {
      const whitelisted = await tokenWhitelistInstance.read.getTokens()
      assert.equal(TOKEN_LIST.length, whitelisted.length, `Whitelist count should  ${TOKEN_LIST.length}`)
    })

    test("should have be able to retrieve whitelisted token from address and confirm its whitelist status", async () => {
      const token = await tokenWhitelistInstance.read.getToken([TOKEN_LIST[0].address])
      assert.equal(token[0], true, "Token should exist")

      const whitelisted = await tokenWhitelistInstance.read.isWhitelisted([TOKEN_LIST[0].address])
      assert.equal(whitelisted, true, "Token should be whitelisted")

      const paused = await tokenWhitelistInstance.read.isPaused([TOKEN_LIST[0].address])
      assert.equal(paused, false, "Token should be not be paused")
    })

    test("should still have enough space to whitelist new tokens", async () => {
      const remainingCapacity = await tokenWhitelistInstance.read.getRemainingCapacity()
      const hasSpace = remainingCapacity > 0
      assert.equal(hasSpace, true, "Should still be able to add more tokens")
    })
  })
})
