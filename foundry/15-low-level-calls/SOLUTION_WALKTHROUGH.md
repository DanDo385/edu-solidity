# Project 15: Step-by-Step Solution Walkthrough

> **CLAUDE/.cursorrules compliance**: This document provides the incremental narrative required by the teaching standards. It explains *why* each step exists and what happens in EVM terms (call vs delegatecall vs staticcall).

## Overview

Project 15 teaches low-level calls: `call`, `delegatecall`, and `staticcall`. This walkthrough breaks the solution into explicit steps with EVM-level explanation.

---

## EVM Framing: call vs delegatecall vs staticcall

| Opcode       | Execution context | Storage used | Typical use              |
|-------------|-------------------|--------------|---------------------------|
| **call**    | Target contract   | Target’s     | Normal external calls     |
| **delegatecall** | Caller contract | Caller’s   | Proxies, libraries        |
| **staticcall**  | Target contract | Target’s  | Read-only, no state writes |

**Critical**: `delegatecall` runs the *target’s code* in the *caller’s context*. Storage, `address(this)`, and `balance` belong to the caller. Only `msg.sender`, `msg.value`, and `msg.data` are passed through.

---

## Step 1: call()—Target Context

**What**: `Caller.callSetValue(target, value)` uses `target.call(abi.encodeWithSignature("setValue(uint256)", value))`.

**Why**: Demonstrates standard external call. Execution and storage live in the target.

**EVM Effect**:
- CALL opcode. Target’s `setValue` runs. Target’s storage (slot 0, etc.) is updated. `msg.sender` in the target is `Caller`.

---

## Step 2: delegatecall()—Caller Context

**What**: `DelegateCaller.delegateSetValue(DelegateTarget, value)` uses `target.delegatecall(abi.encodeWithSignature("setValue(uint256)", value))`.

**Why**: Target’s code runs, but storage changes happen in the *caller*. Used in proxies.

**EVM Effect**:
- DELEGATECALL opcode. Target’s bytecode runs in caller’s context. Writes to “slot 0” and “slot 1” in the target’s *layout* actually hit the caller’s slots 0 and 1. Target’s own storage is untouched.

**Misconception**: delegatecall does *not* copy storage. It uses the caller’s storage. Slot positions are determined by variable order in each contract.

---

## Step 3: Storage Layout and Safe Proxies

**What**: SafeProxy and SafeImplementation share the same layout for slot 0 and 1 (`implementation`, `owner`). Additional slots (e.g. `value` in slot 2) are safe if both agree.

**Why**: If layouts differ, delegatecall can corrupt the caller’s storage. Example: MaliciousImplementation has `owner` in slot 0, but the proxy has `implementation` in slot 0. Writing `owner = msg.sender` overwrites the proxy’s implementation pointer.

**EVM Effect**: SSTORE in delegated code writes to `keccak256-based` slot in *caller* storage. Slot index comes from the delegated contract’s layout. Matching layouts prevent corruption.

---

## Step 4: staticcall()—Read-Only

**What**: `target.staticcall(abi.encodeWithSignature("getValue()"))` reads from the target. `staticcall(abi.encodeWithSignature("setValue(uint256)", x))` fails because it would modify state.

**Why**: staticcall reverts if the called code attempts a state change (SSTORE, etc.). Use it for view-like behavior.

**EVM Effect**: STATICCALL opcode. Any state-modifying opcode in the called code causes revert.

---

## Step 5: Fallback for Empty Calldata

**What**: `TargetContract` has `fallback() external {}` so that `target.call("")` succeeds.

**Why**: Empty calldata with no matching function goes to fallback. Without fallback, the call reverts. Demonstrates handling of low-level calls with empty data.

---

## Connection to Tests

- **call tests**: Verify target storage changes and return data.
- **delegatecall tests**: Verify caller storage changes and target storage unchanged.
- **staticcall tests**: Verify reads succeed and writes fail.
- **SafeProxy test**: Verify aligned layout allows safe delegatecall (value set through proxy).
- **Edge case tests**: Verify empty calldata and EOA behavior.

---

*This walkthrough satisfies the "break into small, explicit steps" and "EVM call/delegatecall/staticcall" requirements.*
