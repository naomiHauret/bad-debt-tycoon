import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { CATALOG } from "@/engine/assets/catalog/catalog-001"
import { prepareCardForRegistration } from "@/engine/features/catalog/cards"
import { prepareObjectiveForRegistraton } from "@/engine/features/catalog/objectives"

// biome-ignore lint/style/noDefaultExport: - i don't want to bother rn
export default buildModule("DeckCatalog", (m) => {
  // Deploy the catalog contract
  const catalog = m.contract("TournamentDeckCatalog")

  const preparedCards = CATALOG.cards.list.map(prepareCardForRegistration)
  const preparedObjectives = CATALOG.objectives.list.map(prepareObjectiveForRegistraton)

  // Register each card and objectives individually
  preparedCards.forEach((card, index) => {
    m.call(catalog, "registerCard", [card], {
      id: `register_card_${card.cardId}`,
    })
  })

  // Prepare objectives for registration
  preparedObjectives.forEach((objective, index) => {
    m.call(catalog, "registerObjective", [objective], { id: `objective_${objective.objectiveId}_${index}` })
  })
  return { catalog }
})
