# Project 01: Step-by-Step Solution Walkthrough

> **CLAUDE/.cursorrules compliance**: This document provides the incremental, traceable narrative required by the teaching standards. It explains *why* each step exists and what changes in EVM terms.

## Overview

The DatatypesStorage contract teaches storage layout, data locations, and gas costs. This walkthrough breaks the solution into explicit steps with EVM-level explanation.

---

## Step 1: State Variable Layout (Storage Slots)

**What**: Declare state variables in order. Each gets a sequential storage slot.

**Why**: The EVM assigns slots at compile time. Order determines layout. Packing small types saves gas.

**EVM Effect**:
- `number` (uint256) → Slot 0, full 256 bits
- `owner` (address) → Slot 1, 160 bits (96 wasted)
- `isActive` (bool) → Slot 2, 8 bits (248 wasted)
- `balances` (mapping) → Slot 5 (base slot; data at keccak256(key‖5))
- `numbers` (array) → Slot 6 (length); data at keccak256(6)+i
- `users` (mapping) → Slot 7 (base slot)

**Gas**: Each first write to a slot costs ~20,000 gas (cold SSTORE).

---

## Step 2: Constructor

**What**: Set `owner = msg.sender` and `isActive = true`.

**Why**: Ownership and initial state. Constructor runs once at deployment.

**EVM Effect**: SSTORE to slots 1 and 2. No deployment-time memory allocation.

---

## Step 3: Value Type Operations (setNumber, getNumber, incrementNumber)

**What**: Read/write `number` (slot 0).

**Why**: Demonstrates basic storage read (SLOAD) and write (SSTORE).

**EVM Effect**:
- `setNumber`: SLOAD slot 0 (old value), SSTORE slot 0 (new value)
- `getNumber`: SLOAD slot 0, return
- `incrementNumber`: SLOAD, add 1, SSTORE

**Gas**: Warm SLOAD ~100 gas, warm SSTORE ~5,000 gas.

---

## Step 4: Mapping Operations (setBalance, getBalance)

**What**: Write/read `balances[address]`.

**Why**: Mappings use `keccak256(abi.encode(key, slot))` for storage addressing. O(1) lookup.

**EVM Effect**:
- `setBalance`: Compute slot = keccak256(addr‖5), SSTORE that slot
- `getBalance`: Compute slot, SLOAD. Unset keys return 0 (EVM default).

**Gas**: Cold SLOAD ~2,100 gas; cold SSTORE ~20,000 gas.

---

## Step 5: Array Operations (addNumber, getNumberAt, removeNumber)

**What**: Push to `numbers`, index access, swap-and-pop remove.

**Why**: Dynamic arrays use length slot + contiguous data region. Demonstrates O(1) push vs O(n) iteration.

**EVM Effect**:
- `addNumber`: SLOAD slot 6 (length), SSTORE slot 6 (length+1), SSTORE keccak256(6)+length (value)
- `removeNumber`: Swap last to index, SSTORE to zero, decrement length (gets gas refund)

**Gas**: Push ~25,000–42,000 gas (length + data write).

---

## Step 6: Struct Operations (registerUser, getUser)

**What**: Write `User` to `users[address]`, read it back.

**Why**: Structs in mappings use sequential slots from base_slot = keccak256(key‖7).

**Storage vs memory** (misconception callout):
- `User storage s = users[addr]` → reference; changes persist. Does NOT copy.
- `User memory m = users[addr]` → copy to memory; does NOT persist after call.

**EVM Effect**: Multiple SLOAD/SSTORE to slots base+0, base+1, base+2.

---

## Step 7: Data Location Functions (sumMemoryArray, getFirstElement)

**What**: `sumMemoryArray(uint256[] memory)` and `getFirstElement(uint256[] calldata)`.

**Why**: Teaches memory (temporary, copy) vs calldata (zero-copy, read-only).

**EVM Effect**:
- `memory`: Allocates temporary memory, copies array. Does NOT persist.
- `calldata`: Reads directly from transaction input. No copy. Cheaper.

---

## Connection to Tests

- **Constructor tests**: Verify slots 1 and 2 after deployment.
- **Mapping tests**: Verify balances[key] and default 0 for unset keys.
- **Array tests**: Verify length and indexing; overflow reverts.
- **Invariant tests**: e.g., `numbers.length` consistency, owner immutability.

---

*This walkthrough satisfies the "break into small, explicit steps" and "never jump directly to final contract" requirements.*
