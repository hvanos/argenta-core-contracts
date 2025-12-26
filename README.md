<!--
This README provides an overview of the Argenta CDPai protocol.  The goal of
Argenta is to implement a collateralised debt position (CDP) system that can
support ETH and liquid‑staking tokens (LSTs) as collateral.  The protocol is
designed to be extensible, modular and safe.  It draws inspiration from
existing open source projects like MakerDAO, Liquity V2, Chainlink and
OpenZeppelin while introducing agent‑native hooks and smart session
permissions (ERC‑7715) for automated risk management.

The repository structure is organised to work with Hardhat v2 and
TypeScript.  Tests and deployment scripts are kept separate from
contracts, and helper utilities live in their own folders.  Each
contract is accompanied by an interface when appropriate.
-->

# Argenta

## MetaMask Smart Accounts / Advanced Permissions (Hackathon Track)

This repository contains **core Argenta CDP contracts** and **agent registries**.

- The **main flow** for MetaMask Hackathon uses **MetaMask Smart Accounts Kit + Advanced Permissions (ERC-7715)** to authorize and execute transactions on behalf of users.
- Any `SessionPermissionVerifier` / `SessionExecutor` contracts included here are kept under `contracts/legacy/` for **local experimentation/tests only** and are **not** part of the recommended production/hackathon main flow.

 – USDa CDP Protocol

Argenta (USDa) is a prototype implementation of a CDP protocol for
Ethereum.  The protocol lets users lock ETH or a supported liquid‑
staking token (LST) as collateral and mint USDa, a stablecoin backed
by that collateral.  It includes modules for risk management, interest
rate modelling, liquidation and oracles.  In addition it shows how
smart session permissions (ERC‑7715) and a simple agent registry
could be integrated to support automated risk reduction by off‑chain
agents.

**Status:** prototype/reference implementation – do not use in
production without a thorough audit.  All contracts are written for
Sepolia testing.

## Features

- **Modular CDP vault:** users can open, adjust and close vaults via
  the `ArgentaVault` contract.  Collateral and debt accounting is done in
  separate modules for clarity.
- **Collateral registry:** `CollateralRegistry` keeps track of
  supported collateral types (ETH, wstETH, rETH, etc.) and their risk
  parameters defined in `RiskParams`.
- **Debt engine and interest rate model:** `DebtEngine` handles
  minting and burning of the stablecoin and accrues interest based on
  a plug‑in `InterestRateModel`.
- **Oracle routing:** the `OracleRouter` aggregates price feeds from
  external oracles (e.g. Chainlink) via adapters such as
  `ETHUSDOracle` and `LSTPriceOracle`.
- **Liquidation module:** `LiquidationModule` performs liquidations
  when a vault’s health factor drops below a threshold.  A separate
  `SafetyGuard` enforces global and per‑vault caps and slippage
  controls.
- **Smart session integration:** `SessionPermissionVerifier` and
  `SessionExecutor` demonstrate how an off‑chain agent could be
  granted granular permissions to act on behalf of a vault owner using
  ERC‑7715 smart sessions.  These contracts should be viewed as
  examples and extended as needed.
- **Agent registry:** `AgentRegistry`, `ReputationRegistry` and
  `ValidationRegistry` show a simple on‑chain registry for agents.
  Off‑chain agents can publish metadata and submit proofs of completed
  jobs.  This is a starting point for integrating ERC‑8004 (A2A).

## Requirements

- Node.js v18+
- Yarn or npm
- Hardhat v2
- TypeScript
- Sepolia network with an RPC provider

## Getting Started

1. **Clone the repository** and install dependencies:

```bash
git clone <this repo>
cd argenta
npm install
# or yarn install
```

2. **Compile contracts**:

```bash
npx hardhat compile
```

3. **Run tests**:

```bash
npx hardhat test
```

4. **Deploy to Sepolia**:

Update `scripts/deploy.ts` with your deployer account and RPC URL,
then run:

```bash
npx hardhat run scripts/deploy.ts --network sepolia
```

5. **Interact with the protocol** via Hardhat console or your own
front‑end.  Example usage is provided in the tests.

## Directory Structure

```
argenta/
├── contracts/            # Solidity smart contracts
│   ├── ArgentaVault.sol
│   ├── CollateralRegistry.sol
│   ├── RiskParams.sol
│   ├── DebtEngine.sol
│   ├── InterestRateModel.sol
│   ├── LiquidationModule.sol
│   ├── SafetyGuard.sol
│   ├── SessionPermissionVerifier.sol
│   ├── SessionExecutor.sol
│   ├── OracleRouter.sol
│   ├── ETHUSDOracle.sol
│   ├── LSTPriceOracle.sol
│   ├── AgentRegistry.sol
│   ├── ReputationRegistry.sol
│   ├── ValidationRegistry.sol
│   ├── RoleManager.sol
│   ├── Stablecoin.sol
│   ├── interfaces/       # Interfaces for contracts
│   │   ├── IArgentaVault.sol
│   │   ├── ICollateralRegistry.sol
│   │   ├── IDebtEngine.sol
│   │   ├── IInterestRateModel.sol
│   │   ├── ILiquidationModule.sol
│   │   ├── IOracleRouter.sol
│   │   └── ISessionManager.sol
│   └── utils/            # Utility libraries (if needed)
│       └── Math.sol
├── scripts/             # Deployment scripts
│   └── deploy.ts
├── test/                # Hardhat tests (TypeScript)
│   └── cdp.test.ts
├── helpers/             # Helper utilities for tests/scripts
│   ├── constants.ts
│   └── utils.ts
├── hardhat.config.ts    # Hardhat configuration using TS
├── package.json         # NPM package configuration
├── tsconfig.json        # TypeScript configuration
└── .gitignore
```

## Contributing & Extending

This repository is meant as a learning resource and starting point for
deeper experimentation.  It lacks many features you would find in a
production grade protocol, such as governance, multi‑collateral
management, auditing or integration with real agents.  Pull requests
that improve security, test coverage, documentation or modularity are
welcome.

When extending the protocol:

- **Follow modular design** so that each component can be audited and
  upgraded independently.
- **Avoid reentrancy** in sensitive functions and rely on
  OpenZeppelin’s reentrancy guard where appropriate.
- **Document every public function** with NatSpec comments.  This
  prototype includes minimal comments for brevity.
- **Write tests**.  The included tests are illustrative; comprehensive
  testing is necessary before mainnet deployment.

## References

- [Liquity V2 source code](https://github.com/liquity) – open source
  implementation of a CDP‑style lending protocol.
- [MakerDAO modules](https://github.com/sky-ecosystem) – numerous
  contracts for multi‑collateral CDP, DSR, auctions, etc.
- [Chainlink contracts](https://github.com/smartcontractkit/chainlink)
  – for oracles and price feeds.
- [OpenZeppelin Contracts](https://github.com/openzeppelin/openzeppelin-contracts)
  – battle‑tested standard library.


## Deploy (Sepolia)

Core:
```bash
npm run deploy:core
```

Agent registries:
```bash
npm run deploy:agents
```

Mocks (optionally reuse router from core):
```bash
ORACLE_ROUTER=<oracleRouterAddress> npm run deploy:mocks
```
