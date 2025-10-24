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
 * Objective instance definition (not a template - specific values)
 */
export interface ObjectiveDefinition {
  objectiveId: number
  objectiveType: ObjectiveValue
  target: ObjectiveTargetValue
}
