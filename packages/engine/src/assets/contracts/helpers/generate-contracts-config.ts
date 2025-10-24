/** biome-ignore-all lint/style/useNamingConvention: - */

import { existsSync, writeFileSync } from "fs"
import { join } from "path"
import type { WhitelistedChainSlug } from "@/engine/assets/chains/config"
import { WHITELISTED_CHAIN_SLUG, WHITELISTED_SLUG_TO_CHAIN_ID } from "@/engine/assets/chains/config"

const CHAIN_SLUG_TO_FOLDER: Record<WhitelistedChainSlug, string> = Object.entries(WHITELISTED_SLUG_TO_CHAIN_ID).reduce(
  (acc, [slug, chainId]) => {
    acc[slug as WhitelistedChainSlug] = `chain-${chainId}`
    return acc
  },
  {} as Record<WhitelistedChainSlug, string>,
)

interface ContractMapping {
  importName: string
  artifactPath: string
  addressKey: string | null
  hasAddress: boolean
  exportName: string
}

// Contract mappings with import names and export configurations
const CONTRACT_MAPPINGS: ContractMapping[] = [
  {
    importName: "DECK_CATALOG_CONTRACT",
    artifactPath: "artifacts/DeckCatalog#TournamentDeckCatalog.json",
    addressKey: "DeckCatalog#TournamentDeckCatalog",
    hasAddress: true,
    exportName: "TOURNAMENT_DECK_CATALOG",
  },
  {
    importName: "REGISTRY_CONTRACT",
    artifactPath: "artifacts/Registry#TournamentRegistry.json",
    addressKey: "Registry#TournamentRegistry",
    hasAddress: true,
    exportName: "TOURNAMENT_REGISTRY",
  },
  {
    importName: "TOKEN_WHITELIST_CONTRACT",
    artifactPath: "artifacts/TokenWhitelist#TournamentTokenWhitelist.json",
    addressKey: "TokenWhitelist#TournamentTokenWhitelist",
    hasAddress: true,
    exportName: "TOURNAMENT_TOKEN_WHITELIST",
  },
  {
    importName: "COMBAT_MODULE",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentCombat.json",
    addressKey: null,
    hasAddress: false,
    exportName: "TOURNAMENT_COMBAT",
  },
  {
    importName: "FACTORY_CONTRACT",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentFactory.json",
    addressKey: "TournamentFactorySystem#TournamentFactory",
    hasAddress: true,
    exportName: "TOURNAMENT_FACTORY",
  },
  {
    importName: "HUB_MODULE",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentHub.json",
    addressKey: null,
    hasAddress: false,
    exportName: "TOURNAMENT_HUB",
  },
  {
    importName: "MYSTERY_DECK_MODULE",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentMysteryDeck.json",
    addressKey: null,
    hasAddress: false,
    exportName: "TOURNAMENT_MYSTERY_DECK",
  },
  {
    importName: "RANDOMIZER_MODULE",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentRandomizer.json",
    addressKey: null,
    hasAddress: false,
    exportName: "TOURNAMENT_RANDOMIZER",
  },
  {
    importName: "TRADING_MODULE",
    artifactPath: "artifacts/TournamentFactorySystem#TournamentTrading.json",
    addressKey: null,
    hasAddress: false,
    exportName: "TOURNAMENT_TRADING",
  },
]

function checkDeploymentExists(chainSlug: WhitelistedChainSlug): boolean {
  const folderName = CHAIN_SLUG_TO_FOLDER[chainSlug]
  const basePath = join(process.cwd(), "ignition/deployments", folderName)

  if (!existsSync(basePath)) {
    return false
  }

  // Check if deployed_addresses.json exists
  const addressesPath = join(basePath, "deployed_addresses.json")
  if (!existsSync(addressesPath)) {
    return false
  }

  // Check if all required artifacts exist
  for (const mapping of CONTRACT_MAPPINGS) {
    const artifactPath = join(basePath, mapping.artifactPath)
    if (!existsSync(artifactPath)) {
      console.warn(` Missing artifact: ${artifactPath}`)
      return false
    }
  }

  return true
}

function generateNetworkFile(chainSlug: WhitelistedChainSlug): string {
  const folderName = CHAIN_SLUG_TO_FOLDER[chainSlug]
  const deploymentsPath = `@/engine/ignition/deployments/${folderName}`

  // Generate imports
  const imports: string[] = []

  for (const mapping of CONTRACT_MAPPINGS) {
    imports.push(`import ${mapping.importName} from "${deploymentsPath}/${mapping.artifactPath}"`)
  }

  // Add deployed_addresses import
  imports.push(`\nimport CONTRACT_ADDRESSES from "${deploymentsPath}/deployed_addresses.json"`)

  // Generate exports
  const infraExports: string[] = []
  const moduleExports: string[] = []

  for (const mapping of CONTRACT_MAPPINGS) {
    if (mapping.hasAddress && mapping.addressKey) {
      infraExports.push(`export const ${mapping.exportName} = {
  address: CONTRACT_ADDRESSES["${mapping.addressKey}"] as \`0x\${string}\`,
  abi: ${mapping.importName}.abi,
}`)
    } else {
      moduleExports.push(`export const ${mapping.exportName} = {
  abi: ${mapping.importName}.abi,
}`)
    }
  }

  // Combine everything
  return `// This file is auto-generated. Do not edit manually.
// Generated on: ${new Date().toISOString()}

${imports.join("\n")}

// Infrastructure Contracts
${infraExports.join("\n\n")}

// Module Contracts
${moduleExports.join("\n")}`
}

export function generateAllContractConfigs(): void {
  console.log("Starting contract configuration generation...\n")

  const generatedNetworks: WhitelistedChainSlug[] = []
  const outputDir = join(process.cwd(), "src/assets/contracts")

  for (const chainSlug of Object.values(WHITELISTED_CHAIN_SLUG)) {
    console.log(`\n Processing ${chainSlug}...`)

    if (!checkDeploymentExists(chainSlug)) {
      console.warn(` Skipping ${chainSlug} - deployment not found or incomplete`)
      continue
    }

    const fileContent = generateNetworkFile(chainSlug)
    const outputPath = join(outputDir, `${chainSlug}.ts`)

    writeFileSync(outputPath, fileContent)
    console.log(`Generated ${chainSlug}.ts`)

    generatedNetworks.push(chainSlug)
  }

  if (generatedNetworks.length === 0) {
    console.error("\nNo contract configurations generated!")
    process.exit(1)
  }

  console.log("\nContract configuration generation complete!")
  console.log(`📊 Generated configs for ${generatedNetworks.length} network(s): ${generatedNetworks.join(", ")}`)
}

// Run if executed directly
if (require.main === module) {
  generateAllContractConfigs()
}
