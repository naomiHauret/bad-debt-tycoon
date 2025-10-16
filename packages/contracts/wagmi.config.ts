import { defineConfig } from "@wagmi/cli"
import { hardhat } from "@wagmi/cli/plugins"

// biome-ignore lint/style/noDefaultExport: i don't care about this in config files
export default defineConfig({
  out: "src/generated.ts",
  plugins: [
    hardhat({
      project: "./",
      include: ["TournamentCore.json", "Tournament.json", "TournamentRegistry.json", "TournamentTokenWhitelist.json"],
    }),
  ],
})
