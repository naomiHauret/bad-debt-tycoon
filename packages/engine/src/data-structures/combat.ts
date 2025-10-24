import { type Hash, type Address } from "viem";


export interface CombatModuleDefinition { // created with .initialize()
    hub: Address
    gameOracle: Address
}

const COMBAT_OUTCOME = {
    P1Win: 0,
    P2Win: 1,
    Draw: 2
} as const
export type CombatOutcomeValue = typeof COMBAT_OUTCOME[keyof typeof COMBAT_OUTCOME]

export interface CombatResolution {
    player1: Address,
    p1CardsBurned: number
    p2CardsBurned: number
    rpsOutcome: CombatOutcomeValue
    modifierApplied: boolean
    p1LifeDelta: number
    p2LifeDelta: number
    player2: Address
    p1CoinDelta: number
    p2CoinDelta: number
    proofHash: Hash
}

export interface CombatSession {
  player1: Address
  player2: Address
  startedAt: number
  active: boolean
}