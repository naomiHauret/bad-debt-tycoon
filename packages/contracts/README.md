# @bdt/contracts

> Bootstrapped with `bunx hardhat --init`.

Smart contracts for Bad Debt Tycoon onchain systems.
[Built with Hardhat V3](https://hardhat.org/docs/learn-more/whats-new).

## Pre-requisites

- A wallet (preferrably new, or at least one you don't use personally) with :
  - some Arbitrum Sepolia ETH for deployments
  - some PYUSD, USDC
- `node` installed
  - Ensure your `node` version is `>=22.10.0`
- Run `bun install` **at the root of the monorepo** (or use `pnpm`, `npm`, `yarn`... as you wish) to ensure your dependencies are installed

## Getting started

### Set and manage encrypted secrets

We use `keystore` to deal with secrets.
You'll need to set the values of the following variables:

```sh
ARBITRUM_SEPOLIA_RPC_URL # RPC URL for Arbitrum Sepolia
DANGER_DEPLOYER_TESTNET_PK # Private key of the wallet we'll use to deploy on testnet.
```

To do so, define your encrypted variables using `keystore`:

```sh
# in dev, use this
bunx hardhat keystore set --dev <VARIABLE NAME> # eg bunx hardhat keystore set --dev ARBITRUM_SEPOLIA_RPC_URL

# In prod, remove the --dev flag
# Note: the first time you run this command, it will prompt you to create a password for your keystore
# You'll need to enter this password everytime you add a new value
bunx hardhat keystore set <VARIABLE NAME>  # eg bunx hardhat keystore set ARBITRUM_SEPOLIA_RPC_URL
```

Verify your config with `bunx hardhat keystore list` (add `--dev` flag if necessary).

Refer to [the Hardhat docs on managing encrypted variables](https://hardhat.org/docs/learn-more/configuration-variables#managing-encrypted-variables) for the complete list of commands.

### Tests

To run all the tests in the project, execute the following command:

```shell
bun run test # or `bunx hardhat test`

```

You can also selectively run the Solidity or `node:test` tests:

```shell
bun run test:solidity # or `bunx hardhat test solidity`
bun run test:nodejs # or `bunx hardhat test nodejs`
```

#### Deployment

Bad Debt Tycoon uses [Hardhat Ignition modules](https://hardhat.org/ignition/docs/getting-started#overview) to simplify contract deployments. Modules can be deployed to a locally simulated chain or to Arbitrum Sepolia /Base Sepolia.

To run the deployment to a local chain:

```shell
bunx hardhat ignition deploy ignition/modules/<Module Name>.ts --network <network name>
# eg: bunx hardhat ignition deploy ignition/modules/BadDebtTycoon.ts --network arbitrumSepolia
```

> When deploying to a chain (mainnet/testnet), you'll have to ensure the deploying account has funds to send the transaction.
