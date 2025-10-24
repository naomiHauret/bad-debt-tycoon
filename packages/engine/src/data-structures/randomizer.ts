import { type Address } from "viem"

export interface RandomizerModuleDefinition {
  hub: Address
  pythEntropy: Address
  entropyProvider: Address
  admin: Address
}