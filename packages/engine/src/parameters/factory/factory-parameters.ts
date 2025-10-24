import HARDHAT from "./factory.hardhat.json"
import ARBITRUM_SEPOLIA from "./factory.arbitrum-sepolia.json"
import { PLATFORM_FEE } from "@/engine/data-structures/fees"

export const FACTORY_PLATFORM_FEE = PLATFORM_FEE
export const FACTORY_PARAMETERS_HARDHAT = {...HARDHAT} as const 
export const FACTORY_PARAMETERS_ARBITRUM_SEPOLIA = {...ARBITRUM_SEPOLIA} as const 