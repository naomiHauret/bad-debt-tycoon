import {
  BATTLE_RATE,
  type BattleRateValue,
  ELIMINATION_TIER,
  LIVES_MULTIPLIER,
  OBJECTIVE,
  type ObjectiveDefinition,
  STREAK_TIER,
  TRADE_COUNT,
  TRADE_VOLUME,
  type TradeCountValue,
  type TradeVolumeValue,
  VICTORY_RATE,
  type VictoryRateValue,
} from "@/engine/data-structures/objectives"

// ID: 1-12
export const OBJECTIVES_001: Array<ObjectiveDefinition> = [
  {
    objectiveId: 1,
    objectiveType: OBJECTIVE.ResourceLives,
    target: { type: OBJECTIVE.ResourceLives, value: LIVES_MULTIPLIER.X2 }, // 2x starting lives
  },

  {
    objectiveId: 2,
    objectiveType: OBJECTIVE.ResourceCoins,
    target: { type: OBJECTIVE.ResourceCoins, value: 150 }, // 1.5x starting coins
  },

  {
    objectiveId: 3,
    objectiveType: OBJECTIVE.ResourceLives,
    target: { type: OBJECTIVE.ResourceLives, value: LIVES_MULTIPLIER.X3 }, // 3x starting lives (hard)
  },

  {
    objectiveId: 4,
    objectiveType: OBJECTIVE.EliminationCount,
    target: { type: OBJECTIVE.EliminationCount, value: ELIMINATION_TIER.Tier1 }, // Eliminate 25% of players
  },

  {
    objectiveId: 5,
    objectiveType: OBJECTIVE.EliminationCount,
    target: { type: OBJECTIVE.EliminationCount, value: ELIMINATION_TIER.Tier2 }, // Eliminate 50% of players
  },

  {
    objectiveId: 6,
    objectiveType: OBJECTIVE.WinStreak,
    target: { type: OBJECTIVE.WinStreak, value: STREAK_TIER.Tier1 }, // 15 win streak
  },

  {
    objectiveId: 7,
    objectiveType: OBJECTIVE.WinStreak,
    target: { type: OBJECTIVE.WinStreak, value: STREAK_TIER.Tier3 }, // 35 win streak (very hard)
  },

  {
    objectiveId: 8,
    objectiveType: OBJECTIVE.VictoryRate,
    target: { type: OBJECTIVE.VictoryRate, value: VICTORY_RATE.validValues()[1] as VictoryRateValue }, // 70% win rate
  },

  {
    objectiveId: 9,
    objectiveType: OBJECTIVE.VictoryRate,
    target: { type: OBJECTIVE.VictoryRate, value: VICTORY_RATE.validValues()[4] as VictoryRateValue }, // 100% win rate (very hard)
  },

  {
    objectiveId: 10,
    objectiveType: OBJECTIVE.BattleRate,
    target: { type: OBJECTIVE.BattleRate, value: BATTLE_RATE.validValues()[2] as BattleRateValue }, // 30% battle rate
  },

  {
    objectiveId: 11,
    objectiveType: OBJECTIVE.TradeCount,
    target: { type: OBJECTIVE.TradeCount, value: TRADE_COUNT.validValues()[2] as TradeCountValue }, // 30% trades
  },

  {
    objectiveId: 12,
    objectiveType: OBJECTIVE.TradeVolume,
    target: { type: OBJECTIVE.TradeVolume, value: TRADE_VOLUME.validValues()[3] as TradeVolumeValue }, // 100% trade volume
  },
]
