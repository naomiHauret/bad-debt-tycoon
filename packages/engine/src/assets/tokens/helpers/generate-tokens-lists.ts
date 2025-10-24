import { readdirSync, readFileSync, statSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import {
  WHITELISTED_CHAIN_ID_TO_SLUG,
  type WhitelistedChainId,
  type WhitelistedTokenDefinition,
} from "../whitelist/config"

const WHITELIST_DIR = "./src/assets/tokens/whitelist"
const OUTPUT_DIR = "./src/assets/tokens"

// Read all token definitions
const tokenDirs = readdirSync(WHITELIST_DIR).filter((dir) => {
  const fullPath = join(WHITELIST_DIR, dir)
  return statSync(fullPath).isDirectory()
})
const allTokens: Array<WhitelistedTokenDefinition> = tokenDirs.map((dir) => {
  const defPath = join(WHITELIST_DIR, dir, "definition.json")
  return JSON.parse(readFileSync(defPath, "utf-8"))
})

// Generate per-chain exports
for (const [chainId, chainName] of Object.entries(WHITELISTED_CHAIN_ID_TO_SLUG)) {
  const tokensForChain = allTokens.filter(
    (token) =>
      token.deployment[chainId as `${WhitelistedChainId}`] &&
      (token.deployment[chainId as `${WhitelistedChainId}`] as string) !== "",
  )

  const imports = tokensForChain
    .map((token) => `import ${token.id} from './whitelist/${token.id}/definition.json';`)
    .join("\n")

  const tokenList = tokensForChain
    .map(
      (token) => `  {
    id: ${token.id}.id,
    name: ${token.id}.name,
    symbol: ${token.id}.symbol,
    decimals: ${token.id}.decimals,
    address: ${token.id}.deployment["${chainId}"]
  }`,
    )
    .join(",\n")

  const content = `/* Generated file - do not edit manually */
${imports}

export const TOKEN_LIST = [
${tokenList}
] as const;
`

  writeFileSync(join(OUTPUT_DIR, `${chainName}.ts`), content)
  console.log(`Generated ${chainName}.ts with ${tokensForChain.length} tokens`)
}
