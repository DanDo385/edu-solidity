// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancySecurity
 * @notice Skeleton contract for learning reentrancy attacks and the CEI pattern
 * @dev Complete the TODOs. Study src/solution/ for reference.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        LEARNING GOALS - PROJECT 07
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * REENTRANCY MENTAL MODEL:
 * -----------------------
 * 1. Call stack: When Contract A calls Contract B, B can call back into A before A finishes.
 * 2. External call: Sending ETH (e.g. .call{value:}()) triggers the recipient's receive()/fallback().
 * 3. Re-entry: Attacker's receive() calls withdraw() again while first withdraw() is still running.
 * 4. State not updated: If we send ETH BEFORE updating balance, the second call still sees old balance!
 *
 * WHY STATE UPDATE ORDER MATTERS:
 * -------------------------------
 * ❌ WRONG: Send ETH first, update balance second → Attacker re-enters with old balance → drains contract
 * ✅ RIGHT: Update balance first, send ETH second → Re-entered call fails balance check
 *
 * CEI PATTERN (Checks-Effects-Interactions):
 * 1. CHECKS: Validate conditions (balance >= amount)
 * 2. EFFECTS: Update state (balance -= amount)
 * 3. INTERACTIONS: External calls last (send ETH)
 *
 * CONNECTION TO PROJECT 02: We learned .call{value:}() for ETH. Here we learn the danger.
 */
contract ReentrancySecurity {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    function deposit() public payable {
        // TODO: Implement deposit - add msg.value to balances[msg.sender]
        //       Emit Deposit event
        revert("TODO: implement deposit");
    }

    /**
     * @notice VULNERABLE withdraw - for learning only!
     * @dev TODO: Implement the VULNERABLE version that sends ETH before updating balance
     *   Order: (1) require balance check, (2) .call{value: amount}(), (3) balance -= amount
     *   This order allows reentrancy! Attacker's receive() can call withdraw again.
     */
    function withdrawVulnerable(uint256 amount) public {
        // TODO: Implement VULNERABLE withdraw
        //   Wrong order: external call BEFORE state update
        revert("TODO: implement withdrawVulnerable");
    }

    /**
     * @notice SAFE withdraw using CEI pattern
     * @dev TODO: Implement the SAFE version
     *   Order: (1) require balance check, (2) balance -= amount, (3) .call{value: amount}()
     *   Effects BEFORE interactions = reentrancy-safe
     */
    function withdrawSafe(uint256 amount) public {
        // TODO: Implement SAFE withdraw with CEI pattern
        revert("TODO: implement withdrawSafe");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title AttackerContract
 * @notice Skeleton for an attack contract that exploits reentrancy
 * @dev TODO: Implement receive() or fallback() that calls withdrawVulnerable() on the target
 *   The attack: deposit, then call withdrawVulnerable. In receive(), call withdrawVulnerable again.
 */
contract AttackerContract {
    // TODO: Add state for target contract address
    // TODO: Implement constructor to set target
    // TODO: Implement attack function (deposit to target, then withdraw)
    // TODO: Implement receive() or fallback() to re-enter target.withdrawVulnerable()
}
