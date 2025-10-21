/**
 * Distribution types
 */
export const DISTRIBUTION = {
  Uniform: "uniform",
  Gaussian: "gaussian",
  Exponential: "exponential",
  Geometric: "geometric",
} as const
export type DistributionValue = (typeof DISTRIBUTION)[keyof typeof DISTRIBUTION]

/**
 * Distribution configuration
 */
export type ValidDistributionConfig =
  | { type: typeof DISTRIBUTION.Uniform }
  | { type: typeof DISTRIBUTION.Gaussian; params: { mean: number; stdDev: number } }
  | { type: typeof DISTRIBUTION.Exponential; params: { lambda: number } }
  | { type: typeof DISTRIBUTION.Geometric; params: { probability: number } }
