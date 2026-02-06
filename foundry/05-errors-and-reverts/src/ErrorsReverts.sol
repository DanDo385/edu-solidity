// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ErrorsReverts
 * @notice Skeleton contract for learning error handling, reverts, and gas optimization
 * @dev Complete the TODOs to implement all functionality. Study src/solution/ for reference.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        LEARNING GOALS - PROJECT 05
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. **Error Handling**: require, revert, assert
 *    - Different ways to handle errors in Solidity
 *    - Gas cost differences between patterns
 *    - When to use each pattern
 *
 * 2. **Custom Errors**: Gas-efficient error reporting (Solidity 0.8.4+)
 *    - Much cheaper than string messages (~90% gas savings)
 *    - Can include parameters for context
 *    - Recommended for production
 *
 * 3. **Revert Patterns**: Transaction rollback
 *    - All state changes are reverted on failure
 *    - Gas consumed up to revert point (not refunded)
 *    - Essential for security and correctness
 *
 * CONNECTION TO PROJECT 01: Uses storage (balance, totalDeposits) from Project 01
 * CONNECTION TO PROJECT 02: Uses owner pattern and require() from Project 02
 * CONNECTION TO PROJECT 04: Error handling used in modifiers
 */
contract ErrorsReverts {
    // ============================================================
    // CUSTOM ERROR DECLARATIONS (TODO: Declare these)
    // ============================================================
    //
    // Custom errors are declared with: error ErrorName(type param1, type param2);
    // They are gas-efficient alternatives to require(condition, "string")
    //
    // TODO: Declare custom errors:
    //   - InsufficientBalance(uint256 available, uint256 required)
    //   - Unauthorized(address caller)
    //   - InvalidAmount()
    //   - InvariantViolation()

    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(address caller);
    error InvalidAmount();
    error InvariantViolation();

    // ============================================================
    // STATE VARIABLES
    // ============================================================

    address public owner;
    uint256 public balance;
    uint256 public totalDeposits;

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        // TODO: Set owner to msg.sender (the deployer)
        owner = msg.sender;
    }

    // ============================================================
    // ERROR HANDLING PATTERNS - IMPLEMENT THESE
    // ============================================================

    /**
     * @notice Deposit using require() with string message
     * @dev TODO: Implement using require() for validation
     *   1. Require amount > 0 with message "Amount must be positive"
     *   2. Require msg.sender == owner with message "Only owner"
     *   3. Update balance and totalDeposits
     */
    function depositWithRequire(uint256 /* amount */) public {
        // TODO: Implement - uncomment parameter and replace this revert
        revert("TODO: implement depositWithRequire");
    }

    /**
     * @notice Deposit using custom errors (gas-optimized)
     * @dev TODO: Implement using custom errors instead of require strings
     *   Use: if (condition) revert ErrorName(params);
     *   Same logic as depositWithRequire but with InvalidAmount and Unauthorized errors
     */
    function depositWithCustomError(uint256 /* amount */) public {
        // TODO: Implement - uncomment parameter and replace this revert
        revert("TODO: implement depositWithCustomError");
    }

    /**
     * @notice Withdraw with parameterized custom error
     * @dev TODO: Implement withdraw with InsufficientBalance(balance, amount) on failure
     *   Follow CEI: Checks first, then Effects (update balance)
     */
    function withdraw(uint256 /* amount */) public {
        // TODO: Implement - uncomment parameter and replace this revert
        revert("TODO: implement withdraw");
    }

    /**
     * @notice Check internal invariant: totalDeposits >= balance
     * @dev TODO: Use assert() to verify the invariant holds
     *   assert() is for internal consistency - should NEVER fail in correct code
     */
    function checkInvariant() public view {
        // TODO: Implement
        revert("TODO: implement checkInvariant");
    }

    /**
     * @notice Get current balance
     */
    function getBalance() public view returns (uint256) {
        return balance;
    }
}
