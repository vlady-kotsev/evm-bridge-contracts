<div align="center">
    <img width="300px" src="https://github.com/user-attachments/assets/71d9d2e4-f851-4d1c-8a69-9012c41f4f19" alt="Tsunagaru_logo">
  <h1>Tsunagari/つながり</h1>
</div>

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Facets](#facets)
- [Deployment](#deployment)
- [Testing](#testing)
- [License](#license)

## Overview

**Tsunagari** (to connect) is a Diamond Standard (EIP-2535) EVM to EVM bridge smart contracts system written in Solidity and Yul, using the Forge framework.

## Features

- Diamond Standard (EIP-2535) modular upgradeability
- Security by requiring a threshold amount of signatures (n of m)
- No reliance on a centralized service

## Facets

- `DiamondCutFacet`: Manages the facets to be added, replaced, or removed.
- `DiamondLoupeFacet`: Read-only functions for querying the state of the diamond.
- `GovernanceFacet`: Manages the governance of the bridge.
- `CalculatorFacet`: Manages the mathematical calculations for the bridge.
- `TokenManagerFacet`: Manages the minting, burning, locking and unlocking of tokens.

## Deployment

Deployment to local `anvil` blockchain network:

```bash
make deploy-diamond-anvil PK=<PRIVATE_KEY>
```

Deployment to **testnet** blockchain network:

```bash
make deploy-diamond-taiko PK=<PRIVATE_KEY>
```

or

```bash
make deploy-diamond-amoy PK=<PRIVATE_KEY>
```

## Testing

The smart contracts are tested with:

### Unit tests: test coverage report can be generated with:

```bash
make report
```

### Fuzz tests

### Static code analysis with **Slither**: static analysis report can be generated with:

```bash
make staic-check
```

<sub>Note: This requires slither analyzer to be installed.</sub>

### Formal verification with **Certora**: formal verification for the **Fee calculation functionality** can be run with:

```bash
make formal-verification CERTORAKEY=<CERTORA_KEY>
```

<sub>Note: This requires Certora key.</sub>

## License

This project is licensed under the MIT License:

MIT License

Copyright (c) 2024 Limechain 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
