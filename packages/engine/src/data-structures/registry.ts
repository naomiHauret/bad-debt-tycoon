import { type Address } from "viem"

export interface TournamentSystemDefinition {
    hub: Address
    combat: Address
    mysteryDeck: Address
    trading: Address
    randomizer: Address
    exists: boolean
}