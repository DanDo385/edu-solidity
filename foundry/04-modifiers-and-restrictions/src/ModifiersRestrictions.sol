// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ModifiersRestrictions
 * @notice Skeleton contract for learning modifiers and access control
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        PROBLEM STATEMENT
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * What are we trying to learn/build?
 * - Access control: onlyOwner, role-based (onlyRole), and pause (whenNotPaused).
 * - Modifiers as reusable guard logic applied before function bodies.
 * - Keccak256 role IDs for gas-efficient role checks.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        EVM FRAMING
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Modifiers are inlined by the compiler. The `_;` is replaced with the function body.
 * - Checks run first; if they fail, the function body never runs.
 * - msg.sender is set by the EVM at call entry; modifiers validate it.
 * - roles[msg.sender][role] uses nested mapping: slot = keccak256(addr, keccak256(role, base)).
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        LEARNING GOALS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. Implement onlyOwner, onlyRole(bytes32), whenNotPaused modifiers
 * 2. Chain modifiers (e.g. onlyOwner whenNotPaused)
 * 3. Use modifiers for transferOwnership, grantRole, pause
 */
contract ModifiersRestrictions {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    address public owner;
    bool public paused;
    
    mapping(address => mapping(bytes32 => bool)) public roles;

    // ============================================================
    // MODIFIERS
    // ============================================================

    // WHY: Modifiers run before the function body; _; is where the body is inlined.
    // INVARIANT: onlyOwner protects admin actions; onlyRole protects role-gated actions.

    // TODO: Implement modifier onlyOwner — require(msg.sender == owner, "Not owner"); _;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // TODO: Implement modifier onlyRole(bytes32 role) — require(roles[msg.sender][role]); _;
    modifier onlyRole(bytes32 role) {
        require(roles[msg.sender][role], "Missing role");
        _;
    }

    // TODO: Implement modifier whenNotPaused — require(!paused, "Paused"); _;
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        owner = msg.sender;
        roles[msg.sender][ADMIN_ROLE] = true;
        // Fun fact: keccak256 role IDs are deterministic, which keeps role
        // management cheap on L2s and easy to replay on forks like Ethereum
        // Classic if governance ever needs to migrate.
    }
    
    // TODO: function transferOwnership(address newOwner) onlyOwner
    // WHY: Owner change; only current owner can do this.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    // TODO: function grantRole(bytes32 role, address account) onlyOwner
    // WHY: Role assignment; only owner can grant roles.
    function grantRole(bytes32 role, address account) public onlyOwner {
        roles[account][role] = true;
    }

    // TODO: function pause() onlyRole(ADMIN_ROLE)
    // WHY: Emergency pause; only admin can pause.
    function pause() public onlyRole(ADMIN_ROLE) {
        paused = true;
    }

    // TODO: function unpause() onlyRole(ADMIN_ROLE)
    function unpause() public onlyRole(ADMIN_ROLE) {
        paused = false;
    }

    // TODO: Add a function with multiple modifiers, e.g. onlyOwner whenNotPaused
    // WHY: Chaining = both must pass. Order: checks first, effects later.
    function adminAction() public onlyOwner whenNotPaused {
        // Example: admin-only action when not paused
    }
}
