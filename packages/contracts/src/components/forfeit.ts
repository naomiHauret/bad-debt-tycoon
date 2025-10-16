export const FORFEIT_PENALTY = {
  /**
   * Penalty applied to players that forfeit is a fixed % of their stake
   */
  Fixed: 0,
  /**
   * Penalty applied to players that forfeit is varing % based onthe remaining game time
   */
  TimeBased: 1,
} as const
export type ForfeitPenaltyValue = (typeof FORFEIT_PENALTY)[keyof typeof FORFEIT_PENALTY]
