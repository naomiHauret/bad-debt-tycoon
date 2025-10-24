// This file is auto-generated. Do not edit manually.
// Generated on: 2025-10-24T16:18:58.125Z

import ARBITRUM_SEPOLIA_CONTRACTS from "./arbitrum-sepolia.json"
import HARDHAT_CONTRACTS from "./hardhat.json"

export const CONTRACTS_BY_NETWORK = {
  "arbitrum-sepolia": ARBITRUM_SEPOLIA_CONTRACTS,
  hardhat: HARDHAT_CONTRACTS,
} as const

export type NetworkContractConfig = (typeof CONTRACTS_BY_NETWORK)[keyof typeof CONTRACTS_BY_NETWORK]
