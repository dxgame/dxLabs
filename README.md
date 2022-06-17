# POE Game Token


## POE Articles

[History of Proof of Excellence and new possibility — Decentralized Game](https://medium.com/@RagnarDoge/history-of-proof-of-excellence-and-new-possibility-decentralized-game-a7bb75652fc6)

[A design of PoE ( Proof of Excellence) token #1](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-1-fc18fd3413da)

[A design of PoE ( Proof of Excellence) token #2](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-2-23959f3a9dcf)

[A design of PoE ( Proof of Excellence) token #3 — Visual Design](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-3-visual-design-c88fd2b642ce)

[A design of PoE (Proof of Excellence) token #4 — Fair Launch](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-4-fair-launch-3ded68e0b8c4)

[A design of PoE (Proof of Excellence) token #5 — Alternative Maps/Boards for Go Game](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-5-alternative-maps-boards-for-go-game-65d591adb546)

[A design of PoE (Proof of Excellence) token #6-The cost of decentralization and state channels](https://medium.com/@RagnarDoge/a-design-of-poe-proof-of-excellence-token-6-the-cost-of-decentralization-and-state-channels-d6aec8e2ad48)

TODO [A design of PoE (Proof of Excellence) token #6 - Introduce True Randomness](...)

## npx hardhat

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
