/** biome-ignore-all lint/style/useNamingConvention: - */
import type { Address } from "viem"
import type { TournamentRules } from "./tournament"

export interface HubModuleDefinition {
  params: TournamentRules
  creator: Address
  combat: Address
  mysteryDeck: Address
  trading: Address
  randomizer: Address
  registry: Address
  whitelist: Address
  admin: Address
}
