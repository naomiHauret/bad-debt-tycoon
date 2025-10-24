export const PLAYER_STATUS = {
  /**
   * Registered participant in the tournament (staked.)
   */
  Active: 0,
  /**
   * Registered participant that won the tournament (exited, didn't claim prize yet)
   */
  Exited: 1,
  /**
   * Registered participant that forfeited during tournament (forfeit, didn't claim partial refund yet)
   */
  Forfeited: 2,
  /**
   * Registered participant that won and claimed their prize share
   */
  PrizeClaimed: 3,
  /**
   * Registered participant that :
   * - withdrew before tournament started
   * - was refunded due to cancellation
   * - claimed their partial stake after forfeit
   */
  Refunded: 4,
} as const
export type PlayerStatusValue = (typeof PLAYER_STATUS)[keyof typeof PLAYER_STATUS]

export interface TournamentPlayer {
  initialCoins: number
  coins: number
  stakeAmount: number 
  lastDecayTimestamp: number
  combatCount: number
  lives: number
  totalCards: number
  status: PlayerStatusValue
  exists: boolean
  inCombat: boolean
}