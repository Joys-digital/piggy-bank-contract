# piggy-bank-contract

[![Testing](https://github.com/Joys-digital/piggy-bank-contract/actions/workflows/testing.yaml/badge.svg)](https://github.com/Joys-digital/piggy-bank-contract/actions/workflows/testing.yaml)
[![Docs](https://img.shields.io/badge/docs-%F0%9F%93%84-success)](https://joys-digital.github.io/piggy-bank-contract/)

- Lang: Solidity v0.6.12

- Project framework: truffle v5.3.14 (core: 5.3.14)

- Nodejs: v14.17.0

## Overview

### Deployed

- Joys Digital Testnet: -
- Joys Digital Mainnet: -

### Documentation

- [Generated html documentation](https://joys-digital.github.io/piggy-bank-contract/)

### Project structure:

```
contracts
├── Migrations.sol
├── interfaces
│   ├── IPiggyBank.sol
│   └── IVault.sol
├── main
│   ├── PiggyBank.sol
│   └── Vault.sol
├── mocks
└── utils
    └── PiggyBankOwnable.sol
```

- __interfaces/__ - Interfaces for compatibility with other smart contracts

- __main/__ - Main contracts

- __utils/__ - Auxiliary contacts

<!-- ### How it works

![architecture picture](./img/architecture.png) -->

## Installation & Usage

1. Install truffle

2. Install all packages
```
npm i --save-dev
```

### Build project:

```
npm run build
```

### Run linters

```
npm run lint
```

### Deploy

edit network in ```truffle-config.js```
```
truffle migrate --f 2 --network <network name>
```

## License

[MIT License](./LICENSE)
