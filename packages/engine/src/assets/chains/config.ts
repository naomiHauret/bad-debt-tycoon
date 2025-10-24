import { arbitrumSepolia, baseSepolia, hardhat } from "viem/chains"

export const WHITELISTED_CHAIN_SLUG = {
  ArbitrumSepolia: "arbitrum-sepolia",
  BaseSepolia: "base-sepolia",
  Hardhat: "hardhat",
} as const

export const WHITELISTED_CHAIN_ID_TO_SLUG = {
  [arbitrumSepolia.id]: WHITELISTED_CHAIN_SLUG.ArbitrumSepolia,
  [baseSepolia.id]: WHITELISTED_CHAIN_SLUG.BaseSepolia,
  [hardhat.id]: WHITELISTED_CHAIN_SLUG.Hardhat,
}

export const WHITELISTED_SLUG_TO_CHAIN_ID = {
  [WHITELISTED_CHAIN_SLUG.ArbitrumSepolia]: arbitrumSepolia.id,
  [WHITELISTED_CHAIN_SLUG.BaseSepolia]: baseSepolia.id,
  [WHITELISTED_CHAIN_SLUG.Hardhat]: hardhat.id,
}

export type WhitelistedChainSlug = (typeof WHITELISTED_CHAIN_SLUG)[keyof typeof WHITELISTED_CHAIN_SLUG]
export type WhitelistedChainId = keyof typeof WHITELISTED_CHAIN_ID_TO_SLUG
