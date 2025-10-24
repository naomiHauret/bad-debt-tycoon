import assert from "node:assert"
import { before, describe, test } from "node:test"
import { network } from "hardhat"
import { getAddress, isAddress } from "viem"
import { CATALOG } from "@/engine/assets/catalog/catalog-001"
import CatalogDeploymentModule from "@/engine/ignition/modules/DeckCatalog"

async function deployCatalogModuleFixture() {
  const { ignition } = await network.connect()
  return ignition.deploy(CatalogDeploymentModule)
}

describe("TournamentDeckCatalog Deployment", () => {
  let catalogInstance: any
  let accounts: any
  let platformRunner: any

  before(async () => {
    const { viem } = await network.connect()

    const { networkHelpers } = await network.connect()
    accounts = await viem.getWalletClients()
    platformRunner = accounts[0]
    const { catalog } = await networkHelpers.loadFixture(deployCatalogModuleFixture)
    catalogInstance = catalog
  })

  describe("after successful deployment", () => {
    test("should return the deployed contract address", () => {
      assert.ok(isAddress(catalogInstance.address), "Contract address should be valid")
    })

    test("should set the deployer as the platform runner", async () => {
      const ownerAddress = await catalogInstance.read.owner()
      assert.strictEqual(
        ownerAddress.toLowerCase(),
        getAddress(platformRunner.account.address).toLowerCase(),
        "Owner should match deployer",
      )
    })

    test("should have objectives registered", async () => {
      const objectives = await catalogInstance.read.objectiveCount()
      assert.equal(
        objectives,
        CATALOG.objectives.list.length,
        "Objectives count should be equal to number of objectives in catalog",
      )
    })

    test("should have cards registered", async () => {
      const cards = await catalogInstance.read.cardCount()
      assert.equal(cards, CATALOG.cards.list.length, "Cards count should be equal to number of cards in catalog")
    })

    test("should be able to get registered cards by id", async () => {
      const id1 = CATALOG.cards.list[0].templateId
      const id2 = CATALOG.cards.list[CATALOG.cards.list.length - 1].templateId

      const card1 = await catalogInstance.read.getCard([id1])
      const card1Exists = card1.exists

      const card2 = await catalogInstance.read.getCard([id2])
      const card2Exists = card2.exists

      assert.strictEqual(card1Exists, true, "Card 1 should exist in catalog")
      assert.strictEqual(card2Exists, true, "Card 2 should exist in catalog")
    })

    test("should be able to get registered objectives by id", async () => {
      const id1 = CATALOG.objectives.list[0].objectiveId
      const id2 = CATALOG.objectives.list[CATALOG.objectives.list.length - 1].objectiveId

      const objective1 = await catalogInstance.read.getCard([id1])
      const objective1Exists = objective1.exists
      assert.strictEqual(objective1Exists, true, "Objective 1 should exist in catalog")

      const objective2 = await catalogInstance.read.getCard([id2])
      const objective2Exists = objective2.exists
      assert.strictEqual(objective2Exists, true, "Objective 2 should exist in catalog")
    })
  })
})
