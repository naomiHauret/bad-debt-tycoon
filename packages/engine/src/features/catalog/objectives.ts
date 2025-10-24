import { encodeAbiParameters, type Hex, parseAbiParameters } from "viem"
import {
  BATTLE_RATE,
  type BattleRateValue,
  COINS_MULTIPLIER,
  type CoinsMultiplierValue,
  ELIMINATION_TIER,
  LIVES_MULTIPLIER,
  OBJECTIVE,
  type ObjectiveDefinition,
  type ObjectiveTargetValue,
  type ObjectiveValue,
  STREAK_TIER,
  TRADE_COUNT,
  TRADE_VOLUME,
  type TradeCountValue,
  type TradeVolumeValue,
  VICTORY_RATE,
  type VictoryRateValue,
} from "@/engine/data-structures/objectives"

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
): Array<ObjectiveDefinition> {
  const objectives: Array<ObjectiveDefinition> = []
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
      Object.values(LIVES_MULTIPLIER).forEach((lives) => {
        COINS_MULTIPLIER.validValues().forEach((coins) => {
          objectives.push({
            objectiveId: currentId++,
            objectiveType,
            target: { type: objectiveType, lives, coins: coins as CoinsMultiplierValue },
          })
        })
      })
      break
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
