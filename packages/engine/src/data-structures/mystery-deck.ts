import type { Address } from "viem"
import type { TournamentRules } from "./tournament"

export interface MysteryDeckModuleDefinition {
  // created with .initialize()
  hub: Address
  catalog: Pick<TournamentRules, "deckCatalog">
  exludedCards: Pick<TournamentRules, "excludedCardIds">
  drawCost: Pick<TournamentRules, "deckDrawCost">
  shuffleCost: Pick<TournamentRules, "deckShuffleCost">
  peekCost: Pick<TournamentRules, "deckPeekCost">
  gameOracle: Pick<TournamentRules, "deckOracle">
}
