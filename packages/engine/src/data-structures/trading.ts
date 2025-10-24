import type { Address } from "viem"

export interface TradingModuleDefinition {
  hub: Address
  gameOracle: Address
}

export const OFFER_STATUS = {
  Open: 0,
  Cancelled: 1,
  Executed: 2,
}
export type OfferStatusValue = (typeof OFFER_STATUS)[keyof typeof OFFER_STATUS]

export interface OfferResourceBundle {
  lives: number
  coins: number
  rockCards: number
  paperCards: number
  scissorsCards: number
}

export interface TradeOffer {
  creator: Address
  expiresAt: number
  status: OfferStatusValue
  exists: boolean
  offered: OfferResourceBundle
  requested: OfferResourceBundle
}
