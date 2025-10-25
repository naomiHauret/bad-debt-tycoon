/** biome-ignore-all lint/style/useNamingConvention: -- */
import type { Address } from "viem"
import type { ForfeitPenaltyValue } from "./forfeit"

export const TOURNAMENT_STATUS = {
  /**
   * Tournament is open for new players. It :
   * - accepts new participants to enter
   * - allows registered participants to withdraw and get a full refund
   * - can transition to "PendingStart"
   */
  Open: 0, // Accepting players

  /**
   * Game is in progress.
   * - No more new participants
   * - Forfeiting is allowed if configured
   * - Participants can't withdraw for a full refund
   * - Can be cancelled if triggered by platform admin
   * - Can transition to "Cancelled" (should be rare, only during emergency cancellation)
   *   or "Ended"
   */
  Active: 1,

  /**
   * Tournament finished normally.
   * - Winners can claim their prize (only winners)
   * - Creator can claim their fee
   * - Platform can claim its fee
   */
  Ended: 2, // Finished normally

  /**
   * Tournament was cancelled either from the platform runner, or by automatically
   * - Registered participants can claim a full refund
   */
  Cancelled: 3, // Start conditions not met

  /**
   * Max number of participants was reached.
   * - No new participant can join unless a registered participant withdraws
   * - Registered participants can withdraw for a full refund
   * - Tournament can transition to :
   *   - Open (if a participant withdraw)
   *   - Pending start
   *   - Cancelled (if emergency cancellation triggered by platform runner)
   */
  Locked: 4, // Maximum players threshold reached

  /**
   * Tournament is evaluating its current state to determine whether to transition to
   * Cancelled or Active.
   */
  PendingStart: 5,
} as const

export type TournamentStatusValue = (typeof TOURNAMENT_STATUS)[keyof typeof TOURNAMENT_STATUS]

export interface TournamentRules {
  startTimestamp: number
  duration: number
  gameInterval: number
  minPlayers: number
  maxPlayers: number
  startPlayerCount: number
  startPoolAmount: bigint
  stakeToken: Address
  minStake: bigint
  maxStake: bigint
  coinConversionRate: number
  decayAmount: bigint
  initialLives: number
  cardsPerType: number
  exitLivesRequired: number
  exitCostBasePercentBPS: number
  exitCostCompoundRateBPS: number
  creatorFeePercent: number
  platformFeePercent: number
  forfeitAllowed: boolean
  forfeitPenaltyType: ForfeitPenaltyValue
  forfeitMaxPenalty: number
  forfeitMinPenalty: number
  deckCatalog: Address
  excludedCardIds: Array<number>
  deckDrawCost: bigint
  deckShuffleCost: bigint
  deckPeekCost: bigint
}

export const RECOMMENDED_SECONDS_PER_CARD = 360
export const MIN_DURATION = 1200
export const MIN_CARDS_PER_TYPE = 1
export const MAX_CARDS_PER_TYPE = 10
export const MIN_PLAYERS_REQUIRED = 2
export const MAX_PLAYERS_LIMIT = 10000
export const MIN_GAME_INTERVAL = 60
export const MAX_GAME_INTERVAL = 3600
export const MAX_CREATOR_FEE_PERCENT = 5
export const MAX_PLATFORM_FEE = 5
export const MAX_COMBINED_FEE_PERCENT = 10
export const MIN_INTERVALS_REQUIRED = 3
