import type { Address } from "viem"
import PYUSD from "./pyusd/definition.json"
import USDC from "./usdc/definition.json"
import { type WhitelistedChainId } from "@/engine/assets/chains/config"

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
