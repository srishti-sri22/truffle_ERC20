# Truffle Token & Faucet (Solidity / Foundry)

This repository contains the **Solidity smart contracts** and **Foundry tooling** for the Truffle ecosystem:
- a minimal ERC20-style token
- a time-based token faucet
- deployment and testing scripts
- local → testnet → mainnet readiness

The goal is correctness, clarity, and production discipline.

---

## Contracts Overview

### 1. `Token.sol`
A lightweight, gas-optimized ERC20-compatible token implementation.

**Key properties**
- Fixed `DECIMALS = 18`
- Immutable owner set at deployment
- Minting restricted to owner
- No external dependencies (no OpenZeppelin inheritance)

**Core features**
- `transfer`
- `approve`
- `transferFrom`
- `mint` (owner-only)
- ERC20 `Transfer` and `Approval` events

**Design intent**
- Explicit storage layout (`s`, `I_`, constants)
- No upgradeability
- Simple ownership model (single immutable owner)

---

### 2. `TokenFaucet.sol`
A controlled faucet that distributes tokens with a cooldown.

**Key features**
- Fixed mint amount per claim
- Per-user cooldown enforcement
- Prevents re-entrancy via logic ordering
- Reads token balance directly from the token contract

**Behavior**
- Users can claim tokens once per cooldown window
- Claims revert if:
  - faucet balance is insufficient
  - cooldown has not expired

**Ownership model**
- The faucet must be the **owner of the token**
- This allows the faucet to mint tokens directly

---

## Ownership Model (Important)

The system follows a **single-owner flow**:

1. `Token` is deployed
2. `TokenFaucet` is deployed with the token address
3. Token ownership is transferred to the faucet
4. Only the faucet can mint new tokens

This ensures:
- no externally owned account can mint
- faucet logic is the sole mint authority

---

## Project Structure

.
├── src/
│ ├── Token.sol
│ └── TokenFaucet.sol
│
├── script/
│ ├── deployAll.s.sol
│ └── transferOwnership.s.sol
│
├── test/
│ ├── testToken.t.sol
│ └── testTokenFaucet.t.sol
│
├── foundry.toml
├── .env
└── README.md