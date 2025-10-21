/**
 * Resource types
 */
export const RESOURCE = {
  Coins: "Coins",
  Lives: "Lives",
  Both: "Both",
} as const
export type ResourceValue = (typeof RESOURCE)[keyof typeof RESOURCE]
