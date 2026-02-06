# Project 02: Step-by-Step Solution Walkthrough

> **CLAUDE/.cursorrules compliance**: This document provides the incremental narrative required by the teaching standards. It explains *why* each step exists and what changes in EVM terms.

## Overview

The FunctionsPayable contract teaches function visibility, payable functions, ETH handling, and the Checks-Effects-Interactions (CEI) pattern. This walkthrough breaks the solution into explicit steps with EVM-level explanation.

---

## EVM Framing: How Calls Enter the Contract

**Where do `msg.value`, `msg.sender`, and `msg.data` come from?**

- **msg.sender**: Set by the EVM when a call enters. It is the address of the immediate caller (or the contract that invoked this call).
- **msg.value**: The wei amount sent with the CALL opcode. Lives in the transaction/calldata envelope; the EVM pushes it onto the stack at call entry.
- **msg.data**: The raw calldata (function selector + ABI-encoded args). Read-only; no copy unless you explicitly load it into memory.

**Mental model**: Every external call is a message. The EVM passes `msg.sender`, `msg.value`, and `msg.data` as part of the call context. Your contract code runs with this context until it returns or reverts.

---

## Step 1: State Variables and Storage Layout

**What**: Declare `owner` and `balances` mapping.

**Why**: Owner is used for access control. Balances track deposits per address (Project 01 mapping pattern).

**EVM Effect**:
- `owner` → Slot 0
- `balances` → Slot 1 (base); actual data at `keccak256(abi.encode(addr, 1))`

---

## Step 2: Visibility: public, external, internal, private

**What**: Implement `publicSquare`, `externalCube`, `internalDouble`, `privateTriple`.

**Why**: Teaches who can call what. `external` saves gas when called from outside (no calldata copy for internal use).

**EVM Effect**: Compiler generates different entry points. `external` functions are called via CALL; `internal`/`private` may be inlined.

---

## Step 3: Payable Constructor

**What**: `constructor() payable` sets `owner = msg.sender` and optionally records deployment ETH.

**Why**: Contract can receive ETH at deployment. `msg.sender` at deploy time is the deployer.

**EVM Effect**: Constructor runs once. Any ETH sent with the deployment transaction increases `address(this).balance`.

---

## Step 4: Payable deposit() and receive()/fallback()

**What**: `deposit()` requires `msg.value > 0`, updates `balances[msg.sender]`, emits event. `receive()` and `fallback()` handle plain ETH and unknown selectors.

**Why**: Multiple ways to send ETH; all must update accounting consistently.

**EVM Effect**:
- `deposit()`: CALL with selector; `msg.value` in wei is added to `balances[msg.sender]` (SSTORE).
- `receive()`: Called when calldata is empty and value &gt; 0.
- `fallback()`: Called when no function matches and (optionally) value is sent.

**Misconception**: `receive()` and `fallback()` are NOT called when you use `contract.deposit{value: X}()`. That goes to `deposit()`. They handle *other* call patterns (e.g. plain `send`/`transfer` or unknown selectors).

---

## Step 5: Withdraw and CEI Pattern

**What**: `withdraw(amount)` validates balance, decrements `balances[msg.sender]`, then sends ETH via `msg.sender.call{value: amount}("")`.

**Why**: CEI prevents reentrancy. Update state *before* the external call so re-entrant calls see updated state.

**EVM Effect**:
1. **Checks**: `require(balances[msg.sender] >= amount)` — SLOAD, compare.
2. **Effects**: `balances[msg.sender] -= amount` — SSTORE. State is updated.
3. **Interactions**: `msg.sender.call{value: amount}("")` — CALL opcode. Recipient's `receive()` or `fallback()` may run. If we had done the call first, they could re-enter `withdraw` and pass the balance check again with stale state.

**Connection**: Project 07 builds on this—vulnerable bank does interaction before effects.

---

## Connection to Tests

- **Visibility tests**: Verify `external`/`internal`/`private` callability.
- **Deposit tests**: Verify `balances` and `msg.value` handling.
- **Withdraw tests**: Verify CEI ordering (no reentrancy) and correct accounting.
- **receive/fallback tests**: Verify plain ETH and unknown selectors are handled.

---

*This walkthrough satisfies the "break into small, explicit steps" and "EVM framing" requirements.*
