import type { Address } from "viem"
import { arbitrumSepolia, baseSepolia } from "viem/chains"
import PYUSD from "./pyusd/definition.json"
import USDC from "./usdc/definition.json"

export const WHITELISTED_CHAIN_SLUG = {
  ArbitrumSepolia: "arbitrum-sepolia",
  BaseSepolia: "base-sepolia",
} as const

export const WHITELISTED_CHAIN_ID_TO_SLUG = {
  [arbitrumSepolia.id]: WHITELISTED_CHAIN_SLUG.ArbitrumSepolia,
  [baseSepolia.id]: WHITELISTED_CHAIN_SLUG.BaseSepolia,
}

export const WHITELISTED_SLUG_TO_CHAIN_ID = {
  [WHITELISTED_CHAIN_SLUG.ArbitrumSepolia]: arbitrumSepolia.id,
  [WHITELISTED_CHAIN_SLUG.BaseSepolia]: baseSepolia.id,
}

export type WhitelistedChainSlug = (typeof WHITELISTED_CHAIN_SLUG)[keyof typeof WHITELISTED_CHAIN_SLUG]
export type WhitelistedChainId = keyof typeof WHITELISTED_CHAIN_ID_TO_SLUG

export interface WhitelistedTokenDefinition {
  id: string
  name: string
  symbol: string
  decimals: number
  src: string
  deployment: Record<`${WhitelistedChainId}`, Address>
}

export const WHITELISTED_TOKEN_ID = {
  [PYUSD.id]: "pyusd",
  [USDC.id]: "usdc",
} as const

export type WhitelistedTokenIdValue = (typeof WHITELISTED_TOKEN_ID)[keyof typeof WHITELISTED_TOKEN_ID]
