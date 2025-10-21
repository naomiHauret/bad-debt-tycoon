import { encodeAbiParameters, type Hex, parseAbiParameters } from "viem"

/**
 * Lives multiplier tiers
 */
export const LIVES_MULTIPLIER = {
  X1: 100,
  X2: 200,
  X3: 300,
} as const
export type LivesMultiplierValue = (typeof LIVES_MULTIPLIER)[keyof typeof LIVES_MULTIPLIER]

/**
 * Coins multiplier range (step of 50)
 */
export const COINS_MULTIPLIER = {
  Min: 50,
  Max: 300,
  Step: 50,
  // Helper to generate valid values
  validValues: () => {
    const values: number[] = []
    for (let i = COINS_MULTIPLIER.Min; i <= COINS_MULTIPLIER.Max; i += COINS_MULTIPLIER.Step) {
      values.push(i)
    }
    return values
  },
} as const
export type CoinsMultiplierValue = 50 | 100 | 150 | 200 | 250 | 300

/**
 * Streak tiers (Win/Lose streaks)
 */
export const STREAK_TIER = {
  Tier1: 15,
  Tier2: 25,
  Tier3: 35,
  Tier4: 50,
} as const
export type StreakTierValue = (typeof STREAK_TIER)[keyof typeof STREAK_TIER]

/**
 * Elimination count tiers (%)
 */
export const ELIMINATION_TIER = {
  Tier1: 25,
  Tier2: 50,
  Tier3: 75,
  Tier4: 100,
} as const
export type EliminationTierValue = (typeof ELIMINATION_TIER)[keyof typeof ELIMINATION_TIER]

/**
 * Battle rate percentage tiers
 */
export const BATTLE_RATE = {
  Min: 10,
  Max: 30,
  Step: 10,
  validValues: () => {
    const values: number[] = []
    for (let i = BATTLE_RATE.Min; i <= BATTLE_RATE.Max; i += BATTLE_RATE.Step) {
      values.push(i)
    }
    return values
  },
} as const
export type BattleRateValue = 10 | 20 | 30

/**
 * Victory rate percentage tiers
 */
export const VICTORY_RATE = {
  Min: 60,
  Max: 100,
  Step: 10,
  validValues: () => {
    const values: number[] = []
    for (let i = VICTORY_RATE.Min; i <= VICTORY_RATE.Max; i += VICTORY_RATE.Step) {
      values.push(i)
    }
    return values
  },
} as const
export type VictoryRateValue = 60 | 70 | 80 | 90 | 100

/**
 * Trade count percentage tiers
 */
export const TRADE_COUNT = {
  Min: 10,
  Max: 30,
  Step: 10,
  validValues: () => {
    const values: number[] = []
    for (let i = TRADE_COUNT.Min; i <= TRADE_COUNT.Max; i += TRADE_COUNT.Step) {
      values.push(i)
    }
    return values
  },
} as const
export type TradeCountValue = 10 | 20 | 30

/**
 * Trade volume percentage tiers
 */
export const TRADE_VOLUME = {
  Min: 25,
  Max: 150,
  Step: 25,
  validValues: () => {
    const values: number[] = []
    for (let i = TRADE_VOLUME.Min; i <= TRADE_VOLUME.Max; i += TRADE_VOLUME.Step) {
      values.push(i)
    }
    return values
  },
} as const
export type TradeVolumeValue = 25 | 50 | 75 | 100 | 125 | 150

/**
 * Objective types (matching smart contract enum)
 */
export const OBJECTIVE = {
  ResourceLives: 0,
  ResourceCoins: 1,
  ResourceAll: 2,
  EliminationCount: 3,
  BattleRate: 4,
  WinStreak: 5,
  LoseStreak: 6,
  VictoryRate: 7,
  PerfectRecord: 8,
  TradeCount: 9,
  TradeVolume: 10,
} as const
export type ObjectiveValue = (typeof OBJECTIVE)[keyof typeof OBJECTIVE]

/**
 * Type-safe objective target values
 * Each objective type has specific valid values baked into the type
 */
export type ObjectiveTargetValue =
  | { type: typeof OBJECTIVE.ResourceLives; value: LivesMultiplierValue }
  | { type: typeof OBJECTIVE.ResourceCoins; value: CoinsMultiplierValue }
  | { type: typeof OBJECTIVE.ResourceAll; lives: LivesMultiplierValue; coins: CoinsMultiplierValue }
  | { type: typeof OBJECTIVE.EliminationCount; value: EliminationTierValue }
  | { type: typeof OBJECTIVE.BattleRate; value: BattleRateValue }
  | { type: typeof OBJECTIVE.WinStreak; value: StreakTierValue }
  | { type: typeof OBJECTIVE.LoseStreak; value: StreakTierValue }
  | { type: typeof OBJECTIVE.VictoryRate; value: VictoryRateValue }
  | { type: typeof OBJECTIVE.PerfectRecord; mustWinAll: boolean }
  | { type: typeof OBJECTIVE.TradeCount; value: TradeCountValue }
  | { type: typeof OBJECTIVE.TradeVolume; value: TradeVolumeValue }

/**
 * Validate objective target value matches smart contract rules
 */
export function validateObjectiveTarget(target: ObjectiveTargetValue): void {
  switch (target.type) {
    case OBJECTIVE.ResourceLives:
      if (!Object.values(LIVES_MULTIPLIER).includes(target.value)) {
        throw new Error(`Invalid lives multiplier: ${target.value}.`)
      }
      break

    case OBJECTIVE.ResourceCoins:
      if (target.value < COINS_MULTIPLIER.Min || target.value > COINS_MULTIPLIER.Max) {
        throw new Error(
          `Invalid coins multiplier: ${target.value}. Must be ${COINS_MULTIPLIER.Min}-${COINS_MULTIPLIER.Max}.`,
        )
      }
      if ((target.value - COINS_MULTIPLIER.Min) % COINS_MULTIPLIER.Step !== 0) {
        throw new Error(`Invalid coins multiplier: ${target.value}. Must be multiple of ${COINS_MULTIPLIER.Step}.`)
      }
      break

    case OBJECTIVE.ResourceAll:
      if (!Object.values(LIVES_MULTIPLIER).includes(target.lives)) {
        throw new Error(`Invalid lives multiplier: ${target.lives}.`)
      }
      if (target.coins < COINS_MULTIPLIER.Min || target.coins > COINS_MULTIPLIER.Max) {
        throw new Error(
          `Invalid coins multiplier: ${target.coins}. Must be ${COINS_MULTIPLIER.Min}-${COINS_MULTIPLIER.Max}.`,
        )
      }
      if ((target.coins - COINS_MULTIPLIER.Min) % COINS_MULTIPLIER.Step !== 0) {
        throw new Error(`Invalid coins multiplier: ${target.coins}. Must be multiple of ${COINS_MULTIPLIER.Step}.`)
      }
      break

    case OBJECTIVE.EliminationCount:
      if (!Object.values(ELIMINATION_TIER).includes(target.value)) {
        throw new Error(`Invalid elimination tier: ${target.value}.`)
      }
      break

    case OBJECTIVE.WinStreak:
    case OBJECTIVE.LoseStreak:
      if (!Object.values(STREAK_TIER).includes(target.value)) {
        throw new Error(`Invalid streak tier: ${target.value}. .`)
      }
      break

    case OBJECTIVE.BattleRate:
      if (!BATTLE_RATE.validValues().includes(target.value)) {
        throw new Error(
          `Invalid battle rate: ${target.value}. Must be one of: ${BATTLE_RATE.validValues().join(", ")}.`,
        )
      }
      break

    case OBJECTIVE.VictoryRate:
      if (!VICTORY_RATE.validValues().includes(target.value)) {
        throw new Error(
          `Invalid victory rate: ${target.value}. Must be one of: ${VICTORY_RATE.validValues().join(", ")}.`,
        )
      }
      break

    case OBJECTIVE.TradeCount:
      if (!TRADE_COUNT.validValues().includes(target.value)) {
        throw new Error(
          `Invalid trade count: ${target.value}. Must be one of: ${TRADE_COUNT.validValues().join(", ")}.`,
        )
      }
      break

    case OBJECTIVE.TradeVolume:
      if (!TRADE_VOLUME.validValues().includes(target.value)) {
        throw new Error(
          `Invalid trade volume: ${target.value}. Must be one of: ${TRADE_VOLUME.validValues().join(", ")}.`,
        )
      }
      break

    case OBJECTIVE.PerfectRecord:
      // No validation needed for boolean
      break

    default:
      throw new Error("Unknown objective type")
  }
}

/**
 * Objective instance definition (not a template - specific values)
 */
export interface ObjectiveDefinition {
  objectiveId: number
  objectiveType: ObjectiveValue
  target: ObjectiveTargetValue
}

/**
 * Encode objective target value into bytes for smart contract
 */
export function encodeObjectiveTarget(target: ObjectiveTargetValue): Hex {
  // Validate before encoding
  validateObjectiveTarget(target)

  switch (target.type) {
    case OBJECTIVE.ResourceLives:
    case OBJECTIVE.ResourceCoins:
      return encodeAbiParameters(parseAbiParameters("uint16"), [target.value])

    case OBJECTIVE.ResourceAll:
      return encodeAbiParameters(parseAbiParameters("uint16, uint16"), [target.lives, target.coins])

    case OBJECTIVE.EliminationCount:
    case OBJECTIVE.BattleRate:
    case OBJECTIVE.WinStreak:
    case OBJECTIVE.LoseStreak:
    case OBJECTIVE.VictoryRate:
    case OBJECTIVE.TradeCount:
    case OBJECTIVE.TradeVolume:
      return encodeAbiParameters(parseAbiParameters("uint8"), [target.value])

    case OBJECTIVE.PerfectRecord:
      return encodeAbiParameters(parseAbiParameters("bool"), [target.mustWinAll])

    default:
      throw new Error("Unknown objective type")
  }
}
type PreparedObjective = Omit<ObjectiveDefinition, "target"> & {
  targetData: `0x${string}`
  exists: boolean
  paused: boolean
}
/**
 * Prepare objective for onchain registration with Catalog contract
 */
export function prepareObjectiveForRegistraton(objective: ObjectiveDefinition): PreparedObjective {
  return {
    exists: true,
    paused: false,
    objectiveId: objective.objectiveId,
    objectiveType: objective.objectiveType,
    targetData: encodeObjectiveTarget(objective.target),
  }
}

/**
 * Generate all valid objective instances for a given type
 */
export function generateAllObjectivesForType(
  objectiveType: ObjectiveValue,
  startId: number,
): ObjectiveDefinition[] {
  const objectives: ObjectiveDefinition[] = []
  let currentId = startId

  switch (objectiveType) {
    case OBJECTIVE.ResourceLives:
      Object.values(LIVES_MULTIPLIER).forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value },
        })
      })
      break

    case OBJECTIVE.ResourceCoins:
      COINS_MULTIPLIER.validValues().forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value: value as CoinsMultiplierValue },
        })
      })
      break

      case OBJECTIVE.ResourceAll:
      // Generate all combinations of lives * coins (good luck players)
      (Object.values(LIVES_MULTIPLIER)).forEach((lives) => {
        COINS_MULTIPLIER.validValues().forEach((coins) => {
          objectives.push({
            objectiveId: currentId++,
            objectiveType,
            target: { type: objectiveType, lives, coins: coins as CoinsMultiplierValue },
          });
        });
      });
      break;
    case OBJECTIVE.EliminationCount:
      Object.values(ELIMINATION_TIER).forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value },
        })
      })
      break

    case OBJECTIVE.WinStreak:
    case OBJECTIVE.LoseStreak:
      Object.values(STREAK_TIER).forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value },
        })
      })
      break

    case OBJECTIVE.PerfectRecord:
      ;[true, false].forEach((mustWinAll) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, mustWinAll },
        })
      })
      break

    // For range-based objectives, generate a few common values
    case OBJECTIVE.BattleRate:
      BATTLE_RATE.validValues().forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value: value as BattleRateValue },
        })
      })
      break

    case OBJECTIVE.VictoryRate:
      VICTORY_RATE.validValues().forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value: value as VictoryRateValue },
        })
      })
      break

    case OBJECTIVE.TradeCount:
      TRADE_COUNT.validValues().forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value: value as TradeCountValue },
        })
      })
      break

    case OBJECTIVE.TradeVolume:
      TRADE_VOLUME.validValues().forEach((value) => {
        objectives.push({
          objectiveId: currentId++,
          objectiveType,
          target: { type: objectiveType, value: value as TradeVolumeValue },
        })
      })
      break


    default:
      throw new Error(`Unsupported objective type: ${objectiveType}`)
  }

  return objectives
}
