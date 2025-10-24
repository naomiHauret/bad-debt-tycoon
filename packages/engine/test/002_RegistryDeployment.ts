import assert from "node:assert"
import { before, describe, test } from "node:test"
import { network } from "hardhat"
import { getAddress, isAddress } from "viem"
import RegistryModule from "@/engine/ignition/modules/Registry"

async function deployRegistryFixture() {
  const { ignition } = await network.connect()
  return ignition.deploy(RegistryModule)
}

describe("TournamentRegistry Deployment", () => {
  let registryInstance: any
  let accounts: any
  let platformRunner: any

  before(async () => {
    const { viem } = await network.connect()

    const { networkHelpers } = await network.connect()
    accounts = await viem.getWalletClients()
    platformRunner = accounts[0]
    const { registry } = await networkHelpers.loadFixture(deployRegistryFixture)
    registryInstance = registry
  })

  describe("after successful deployment", () => {
    test("should return the deployed contract address", () => {
      assert.ok(isAddress(registryInstance.address), "Contract address should be valid")
    })

    test("should set the deployer as the platform runner", async () => {
      const ownerAddress = await registryInstance.read.owner()
      assert.strictEqual(
        ownerAddress.toLowerCase(),
        getAddress(platformRunner.account.address).toLowerCase(),
        "Owner should match deployer",
      )
    })

    test("should not have any tournaments registered yet", async () => {
      const tournaments = await registryInstance.read.getAllTournaments()
      assert.equal(tournaments.length, 0, "Registry tournaments list size should be 0")
    })
  })
})
