# @cdt/contracts

Smart contracts for Crippling Debt Tycoon onchain systems.

---

> Bootstrapped with `bunx hardhat --init`.

## Usage

### Running tests

To run all the tests in the project, execute the following command:

```shell
bun run test # or `bunx hardhat test`

```

You can also selectively run the Solidity or `node:test` tests:

```shell
bun run test:solidity # or `bunx hardhat test solidity`
run test:nodejs # or `bunx hardhat test nodejs`
```

### Deployment

This project includes an example Ignition module to deploy the contract. You can deploy this module to a locally simulated chain or to Sepolia.

To run the deployment to a local chain:

```shell
npx hardhat ignition deploy ignition/modules/<Module Name>.ts
```

To run the deployment to Sepolia, you need an account with funds to send the transaction. The provided Hardhat configuration includes a Configuration Variable called `SEPOLIA_PRIVATE_KEY`, which you can use to set the private key of the account you want to use.

You can set the `SEPOLIA_PRIVATE_KEY` variable using the `hardhat-keystore` plugin or by setting it as an environment variable.

To set the `SEPOLIA_PRIVATE_KEY` config variable using `hardhat-keystore`:

```shell
npx hardhat keystore set SEPOLIA_PRIVATE_KEY
```

After setting the variable, you can run the deployment with the Sepolia network:

```shell
npx hardhat ignition deploy --network sepolia ignition/modules/Counter.ts
```
