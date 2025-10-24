import DECK_CATALOG_CONTRACT from "@/engine/ignition/deployments/chain-31337/artifacts/DeckCatalog#TournamentDeckCatalog.json"
import REGISTRY_CONTRACT from "@/engine/ignition/deployments/chain-31337/artifacts/Registry#TournamentRegistry.json"
import TOKEN_WHITELIST_CONTRACT from "@/engine/ignition/deployments/chain-31337/artifacts/TokenWhitelist#TournamentTokenWhitelist.json"
import COMBAT_MODULE from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentCombat.json"
import FACTORY_CONTRACT from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentFactory.json"
import HUB_MODULE from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentHub.json"
import MYSTERY_DECK_MODULE from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentMysteryDeck.json"
import RANDOMIZER_MODULE from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentRandomizer.json"
import TRADING_MODULE from "@/engine/ignition/deployments/chain-31337/artifacts/TournamentFactorySystem#TournamentTrading.json"

import CONTRACT_ADDRESSES from "@/engine/ignition/deployments/chain-31337/deployed_addresses.json"

// Infra
export const TOURNAMENT_DECK_CATALOG = {
  address: CONTRACT_ADDRESSES["DeckCatalog#TournamentDeckCatalog"],
  abi: DECK_CATALOG_CONTRACT.abi,
}

export const TOURNAMENT_TOKEN_WHITELIST = {
  address: CONTRACT_ADDRESSES["TokenWhitelist#TournamentTokenWhitelist"],
  abi: TOKEN_WHITELIST_CONTRACT.abi,
}

export const TOURNAMENT_REGISTRY = {
  address: CONTRACT_ADDRESSES["Registry#TournamentRegistry"],
  abi: REGISTRY_CONTRACT.abi,
}

export const TOURNAMENT_FACTORY = {
  address: CONTRACT_ADDRESSES["TournamentFactorySystem#TournamentFactory"],
  abi: FACTORY_CONTRACT.abi,
}

// Modules
export const TOURNAMENT_HUB = {
  abi: HUB_MODULE,
}
export const TOURNAMENT_COMBAT = {
  abi: COMBAT_MODULE,
}
export const TOURNAMENT_TRADING = {
  abi: TRADING_MODULE,
}
export const TOURNAMENT_MYSTERY_DECK = {
  abi: MYSTERY_DECK_MODULE,
}
export const TOURNAMENT_RANDOMIZER = {
  abi: RANDOMIZER_MODULE,
}
