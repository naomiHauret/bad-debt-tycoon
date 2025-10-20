/**
 * Secret objectives are optional win conditions assigned randomly to players
 *  when a tournament starts. Completing their secret objective allows the player
 * to exit the game earlier than the exit window typically allows.
 */
export const SECRET_OBJECTIVE = {
  /** Accumulate X lives (1x, 2x, 3x only)  */
  ResourceLives: 0,
  /** Accumulate X coins (0.5x to 3x)  */
  ResourceCoins: 1,
  /** Both lives AND coins  */
  ResourceAll: 2,
  /** Eliminate X players (based on cards)  */
  EliminationCount: 3,
  /** Fight with X% of players  */
  BattleRate: 4,
  /** Win X fights in a row */
  WinStreak: 5,
  /** Lose X fights in a row */
  LoseStreak: 6,
  /** Win >= X% of fights */
  VictoryRate: 7,
  /** Win all OR lose all fights */
  PerfectRecord: 8,
  /** Complete X trades */
  TradeCount: 9,
  /** Trade X% of initial coins */
  TradeVolume: 10,
} as const
export type SecretObjectiveValue = (typeof SECRET_OBJECTIVE)[keyof typeof SECRET_OBJECTIVE]
