import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

// biome-ignore lint/style/noDefaultExport: -
export default buildModule("Registry", (m) => {
  // Deploy registry
  const registry = m.contract("TournamentRegistry")
  return { registry }
})
