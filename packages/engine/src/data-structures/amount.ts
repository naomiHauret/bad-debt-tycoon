/**
 * Amount types
 */
export const AMOUNT = {
  Fixed: "Fixed",
  Percent: "Percent",
  Multiplier: "Multiplier",
} as const
export type AmountValue = (typeof AMOUNT)[keyof typeof AMOUNT]
