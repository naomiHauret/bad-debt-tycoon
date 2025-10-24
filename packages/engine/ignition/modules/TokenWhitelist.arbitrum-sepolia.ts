import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { TOKEN_LIST } from "@/engine/assets/tokens/arbitrum-sepolia"

// biome-ignore lint/style/noDefaultExport: -
export default buildModule("TokenWhitelist", (m) => {
  // Deploy & populate
  const whitelist = m.contract("TournamentTokenWhitelist")
  TOKEN_LIST.forEach((token) => {
    m.call(whitelist, "addToken", [token.address], {
      id: `arb_sepolia_whitelisted_token_${token.id}_${token.address}`,
    })
  })

  return { whitelist }
})

// Sorry for code dedupe
// Wanted deploy a specific token list per chain, but it's not available yet
// https://github.com/NomicFoundation/hardhat/issues/7552
