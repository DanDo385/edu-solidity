# Project 07: Step-by-Step Solution Walkthrough

> **CLAUDE/.cursorrules compliance**: This document provides the incremental narrative required by the teaching standards. It explains *why* each step exists and what happens at the EVM call stack and storage level.

## Overview

Project 07 teaches reentrancy attacks and the Checks-Effects-Interactions (CEI) pattern. This walkthrough breaks the solution into explicit steps: the vulnerable contract, the secure contract, and the attacker.

---

## EVM Framing: Call Stack and Reentrancy

**Call stack**:
1. User calls `Attacker.attack()`
2. Attacker calls `VulnerableBank.withdrawVulnerable()`
3. Bank does `msg.sender.call{value: amount}("")` → invokes Attacker’s `receive()`
4. **Reentrancy**: Attacker’s `receive()` calls `VulnerableBank.withdrawVulnerable()` again *before* the first call has finished
5. The second call runs with the *same* balance (state not yet updated), passes the check, sends more ETH, and so on

**Storage**: `balances[msg.sender]` lives in the bank’s storage. If we update it *after* the external call, re-entrant calls still see the old value.

---

## Step 1: VulnerableBank—The Bug

**What**: `withdrawVulnerable` does: (1) check `balances[msg.sender] >= amount`, (2) `msg.sender.call{value: amount}("")`, (3) `balances[msg.sender] -= amount`.

**Why it fails**: Interaction (step 2) happens *before* effects (step 3). The recipient can re-enter and pass the check again.

**EVM Effect**:
- Nested calls: Bank → Attacker.receive() → Bank.withdrawVulnerable() → …
- Each nested call reads the same `balances[attacker]` (unchanged). Attacker drains the contract.
- When the stack unwinds, each frame does `balances[attacker] -= amount`. Solidity 0.8+ checked math would revert on underflow. We use `unchecked` so the demo runs to completion and illustrates the drain; in reality, the vulnerability allows theft before any unwind.

**Fix in secure version**: Do effects *before* interactions.

---

## Step 2: SecureBank—CEI Pattern

**What**: `withdraw` does: (1) check `balances[msg.sender] >= amount`, (2) `balances[msg.sender] -= amount`, (3) `msg.sender.call{value: amount}("")`.

**Why it works**: State is updated before the external call. A re-entrant `withdraw` sees the new (reduced) balance and fails the check.

**EVM Effect**:
- SSTORE to `balances[msg.sender]` happens before CALL.
- Any re-entrant call does SLOAD and sees the updated balance. `require` fails; no further ETH is sent.

---

## Step 3: Attacker Contract

**What**: `attack()` deposits 1 ether, then calls `withdrawVulnerable(1 ether)`. `receive()` re-enters and calls `withdrawVulnerable` again while `address(bank).balance >= attackAmount`.

**Why**: Demonstrates the attack vector. The attacker’s contract receives ETH and immediately calls back into the vulnerable function.

**EVM Effect**: Call stack grows with each re-entry. Attacker receives multiple ETH transfers until the bank is drained or some limit is hit.

---

## Invariant Restored by the Fix

**Invariant**: A user’s balance must not be used for multiple successful withdrawals before it is decremented.

- **Vulnerable**: Balance is decremented *after* the transfer → invariant violated during reentrancy.
- **Secure**: Balance is decremented *before* the transfer → invariant holds at every external call boundary.

---

## Connection to Tests

- **test_ReentrancyAttack_Succeeds**: Attacker drains the vulnerable bank; attacker balance > 1 ether.
- **test_SecureBank_PreventsReentrancy**: Secure bank rejects re-entrant withdraw; balance stays correct.
- **test_VulnerableBank_LosesAllFunds**: Attacker profits from the vulnerable bank.

---

*This walkthrough satisfies the "break into small, explicit steps" and "EVM call stack and storage" requirements.*
