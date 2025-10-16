import type { HardhatUserConfig } from "hardhat/config";
import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable } from "hardhat/config";
import { arbitrumSepolia } from "viem/chains";

/**
 * @see https://hardhat.org/docs/reference/configuration
 */
const config: HardhatUserConfig = {
  plugins: [
    hardhatToolboxViemPlugin],
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
      },
      production: {
        version: "0.8.28",
        settings: {
          // biome-ignore lint/style/useNamingConvention: hardhat named this, i
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    arbitrumSepolia: {
      type: "http",
      url: configVariable("ARBITRUM_SEPOLIA_RPC_URL") ||arbitrumSepolia.rpcUrls.default.http[0],
      accounts: [configVariable("DANGER_DEPLOYER_TESTNET_PK")],
      chainId: arbitrumSepolia.id, 
    },
  },
} as const;

// biome-ignore lint/style/noDefaultExport: if it's what hardhat wants, let it do its thing
export default config;
