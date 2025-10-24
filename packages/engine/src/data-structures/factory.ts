import type { Abi, Address, GetContractReturnType, WalletClient } from "viem"

export interface FactoryDefinition {
  hubImpl: Address
  combatImpl: Address
  mysteryDeckImpl: Address
  tradingImpl: Address
  randomizerImpl: Address
  registry: Address
  whitelist: Address
  deckCatalog: Address
  pythEntropy: Address
  entropyProvider: Address
  platformAdmin: Address
  gameOracle: Address
  platformFee: number
}


