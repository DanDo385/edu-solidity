// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventsLogging
 * @notice Skeleton contract for learning Solidity events and logging
 * @dev Complete the TODOs to implement all functionality
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        PROBLEM STATEMENT
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * What are we trying to learn/build?
 * - A minimal token-like contract: balances, allowances, transfers, approvals.
 * - Events for every meaningful state change (Transfer, Approval, Deposit, etc.).
 * - Event design for off-chain indexing (indexed params, topic hashes).
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        EVM FRAMING
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Events are emitted via the LOGn opcodes. They do NOT go into contract storage.
 * - Indexed params become topics (up to 3 indexed; topic[0] = event signature).
 * - Non-indexed params go into the data blob.
 * - Nodes build bloom filters from topics for cheap filtering.
 * - msg.sender, block.timestamp, etc. are available when emitting.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        LEARNING GOALS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. Declare events with indexed parameters
 * 2. Emit events for state changes
 * 3. Understand gas costs of events vs storage (events are cheaper for history)
 * 4. Design event schemas for off-chain indexing
 */
contract EventsLogging {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // TODO: Declare public address variable 'owner'
    // WHY: Access control. INVARIANT: Only owner can perform certain actions.
    address public owner;
    // TODO: Declare mapping 'balances' from address to uint256
    // WHY: Track token balance per account. CONNECTION: Project 01 mapping layout.
    mapping(address => uint256) public balances;
    // TODO: Declare mapping 'allowances' from address to address to uint256
    // WHY: allowance[owner][spender] = amount spender can transfer from owner.
    mapping(address => mapping(address => uint256)) public allowances;

    // TODO: (Optional) Add string status per user for updateStatus
    mapping(address => string) public status;

    // ============================================================
    // EVENTS
    // ============================================================
    // WHY: Events are logged separately from storage; indexed params become
    //      topics for off-chain filtering. INVARIANT: Emit for every state change.

    // TODO: Declare event 'Transfer' - indexed sender, indexed recipient, amount
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    // TODO: Declare event 'Approval' - indexed owner, indexed spender, amount
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // TODO: Declare event 'Deposit' - indexed user, amount, timestamp
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);

    // TODO: Declare event 'StatusChanged' - indexed user, oldStatus, newStatus
    event StatusChanged(address indexed user, string oldStatus, string newStatus);

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    constructor() {
        // TODO: Set owner to msg.sender (deployer owns the contract)
        owner = msg.sender;
    }

    // ============================================================
    // FUNCTIONS THAT EMIT EVENTS
    // ============================================================

    function transfer(address _to, uint256 _amount) public {
        // TODO: Implement transfer logic
        // WHY: Core transfer; every state change should emit an event.
        // INVARIANT: Sum of all balances unchanged; sender balance decreases, recipient increases.
        // 1. Require balance >= _amount  2. balances[msg.sender] -= _amount; balances[_to] += _amount
        // 3. emit Transfer(msg.sender, _to, _amount)
    }

    function approve(address _spender, uint256 _amount) public {
        // TODO: Implement approval logic
        // WHY: Allow _spender to transfer up to _amount from msg.sender.
        // 1. allowances[msg.sender][_spender] = _amount
        // 2. emit Approval(msg.sender, _spender, _amount)
    }

    function deposit() public payable {
        // TODO: Implement deposit logic
        // WHY: Accept ETH and credit balance; record timestamp for off-chain analytics.
        // 1. balances[msg.sender] += msg.value
        // 2. emit Deposit(msg.sender, msg.value, block.timestamp)
    }

    function updateStatus(string memory _newStatus) public {
        // TODO: Implement status update
        // WHY: Demonstrate string in events (non-indexed; lives in data blob).
        // 1. string memory oldStatus = status[msg.sender]
        // 2. status[msg.sender] = _newStatus
        // 3. emit StatusChanged(msg.sender, oldStatus, _newStatus)
    }

    // ============================================================
    // VIEW FUNCTIONS
    // ============================================================

    function balanceOf(address _account) public view returns (uint256) {
        // TODO: Replace with return balances[_account]
        return 0;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        // TODO: Replace with return allowances[_owner][_spender]
        return 0;
    }
}
