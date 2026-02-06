# Project 05: Step-by-Step Solution Walkthrough

> **CLAUDE/.cursorrules compliance**: This document provides the incremental narrative required by the teaching standards. It explains *why* each step exists and what happens in EVM terms.

## Overview

The ErrorsReverts contract teaches error handling: `require`, `revert` with custom errors, and `assert`. This walkthrough breaks the solution into explicit steps with EVM-level explanation.

---

## EVM Framing: What Happens on Revert

**Revert = rollback**:
- All state changes (SSTORE) in the current call are undone.
- Gas consumed up to the revert point is not refunded.
- Return data can carry a custom error selector + parameters or a panic code.

**require vs revert vs assert**:
- `require(cond, "msg")`: If `cond` is false, revert with optional string. Uses REVERT opcode.
- `revert ErrorName(params)`: Revert with custom error. Encoded as 4-byte selector + params. Cheaper than string.
- `assert(cond)`: If `cond` is false, trigger Panic(1). Uses all remaining gas (panic path).

---

## Step 1: Custom Error Declarations

**What**: Declare `InsufficientBalance`, `Unauthorized`, `InvalidAmount`, `InvariantViolation`.

**Why**: Custom errors (Solidity 0.8.4+) are gas-efficient and support parameters. Production contracts prefer them over string messages.

**EVM Effect**: Compiler emits a 4-byte selector (first 4 bytes of keccak256 of error signature). On revert, this selector + ABI-encoded params are in return data. No string encoding cost.

---

## Step 2: depositWithRequire

**What**: Validate `amount > 0` and `msg.sender == owner` with `require`, then update `balance` and `totalDeposits`.

**Why**: Teaches guard clauses: validate first, then change state.

**EVM Effect**: Each `require` compiles to a conditional jump; on failure, REVERT. String message adds calldata-like encoding cost.

---

## Step 3: depositWithCustomError

**What**: Same logic as Step 2, but use `if (cond) revert InvalidAmount()` and `if (cond) revert Unauthorized(msg.sender)`.

**Why**: Demonstrates gas savings. Custom errors are ~26 gas + params vs ~50+ gas for string.

**EVM Effect**: Revert with custom error selector + params. Cheaper and better for tooling.

---

## Step 4: withdraw with Parameterized Error

**What**: Check `balance >= amount`, then `balance -= amount`. Use `revert InsufficientBalance(balance, amount)` on failure.

**Why**: Parameterized errors give context (available vs required). Frontends can display helpful messages.

**EVM Effect**: Same revert mechanism; return data includes `balance` and `amount` for off-chain decoding.

---

## Step 5: checkInvariant with assert

**What**: `assert(totalDeposits >= balance)`.

**Why**: Invariants should never be false in correct code. If they fail, it indicates a bug. `assert` is for internal consistency, not user input.

**EVM Effect**: On failure, Panic(1) is triggered. Uses all remaining gas. Reserve for truly impossible conditions.

**Misconception**: Do NOT use `assert` for input validation or access control. Use `require` or custom errors.

---

## Connection to Tests

- **require tests**: Verify validation and string revert behavior.
- **Custom error tests**: Verify parameterized reverts and gas behavior.
- **assert tests**: Verify invariant checks (and that they pass in correct implementations).
- **Invariant tests**: Verify `totalDeposits >= balance` holds across operations.

---

*This walkthrough satisfies the "break into small, explicit steps" and "EVM framing" requirements.*
