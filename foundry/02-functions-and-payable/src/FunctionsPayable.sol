// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FunctionsPayable
 * @notice Skeleton contract for learning functions, payable, and ETH handling
 * @dev Complete the TODOs to implement all functionality
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        PROBLEM STATEMENT
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * What are we trying to learn/build?
 * - A minimal bank: deposit ETH, withdraw ETH, track balances per address.
 * - Function visibility: who can call what (public, external, internal, private).
 * - How contracts receive ETH: payable functions, receive(), fallback().
 * - The Checks-Effects-Interactions (CEI) pattern for safe withdrawals.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        EVM FRAMING
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * When a call enters the contract:
 * - msg.sender: address of the immediate caller (set by the EVM).
 * - msg.value: wei sent with the call (in the transaction envelope).
 * - msg.data: raw calldata (function selector + ABI-encoded args).
 *
 * Payable functions can receive ETH; non-payable reject value > 0.
 * receive() runs on plain ETH (empty calldata); fallback() on unknown selectors.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        LEARNING GOALS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. Master function visibility (public, external, internal, private)
 * 2. Understand the payable modifier
 * 3. Implement receive() and fallback() functions
 * 4. Learn safe ETH transfer patterns (CEI pattern)
 *
 * FUN FACT: Solidity compiles to Yul and then to bytecode. Marking helpers
 * internal often lets the optimizer inline them, shaving jumps and saving gas.
 */
contract FunctionsPayable {
    // ============================================================
    // STATE VARIABLES
    // ============================================================

    // TODO: Declare a public address variable called 'owner'
    // WHY: Access control. CONNECTION: Project 01 storage slot 0.
    address public owner;
    // TODO: Declare a mapping from address to uint256 called 'balances'
    // WHY: Track deposits per address. CONNECTION: Project 01 mapping layout.
    mapping(address => uint256) public balances;
    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Define an event 'Deposited' with indexed sender (address) and amount (uint256)
    event Deposited(address indexed sender, uint256 amount);
    // TODO: Define an event 'Withdrawn' with indexed recipient (address) and amount (uint256)
    event Withdrawn(address indexed recipient, uint256 amount);
    // TODO: Define an event 'Received' with indexed sender (address) and amount (uint256)
    event Received(address indexed sender, uint256 amount);
    // TODO: Define an event 'FallbackCalled' with indexed sender (address), amount (uint256), and data (bytes)
    event FallbackCalled(address indexed sender, uint256 amount, bytes data);
    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement a payable constructor that:
    //       1. Sets owner to msg.sender
    //       2. Accepts ETH during deployment
    constructor() payable {
        owner = msg.sender;
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }
    // ============================================================
    // RECEIVE AND FALLBACK
    // ============================================================

    // TODO: Implement receive() function that:
    //       1. Is external payable
    //       2. Emits Received event
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    // TODO: Implement fallback() function that:
    //       1. Is external payable
    //       2. Emits FallbackCalled event with msg.data
    // These two functions are like the mailroom of your contract: receive()
    // handles plain envelopes (empty calldata) while fallback() routes unknown
    // parcels. Istanbul and later forks repriced gas, so avoid hardcoded limits
    // like transfer/send and stick to call with proper checks.
    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
    // ============================================================
    // EXTERNAL FUNCTIONS
    // ============================================================

    /**
     * @notice External function - only callable from outside
     * @return A message string
     */
    function externalFunction() external pure returns (string memory) {
        // TODO: Return "This is external"
        return "This is external";
    }

    // ============================================================
    // PUBLIC FUNCTIONS
    // ============================================================

    /**
     * @notice Deposit ETH into the contract
     * @dev Increases sender's balance by msg.value
     */
    function deposit() public payable {
        // TODO: Implement
        // 1. Require msg.value > 0
        // 2. Increase balances[msg.sender] by msg.value
        // 3. Emit Deposited event
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit ETH for a specific address
     * @param _recipient The address to credit
     */
    function depositFor(address _recipient) public payable {
        // TODO: Implement
        // 1. Require msg.value > 0
        // 2. Require _recipient is not zero address
        // 3. Increase balances[_recipient] by msg.value
        // 4. Emit Deposited event for _recipient
        require(msg.value > 0, "Amount must be greater than 0"); // prevent reentrancy
        require(_recipient != address(0), "Recipient must not be the zero address"); // prevent reentrancy
        balances[_recipient] += msg.value; // increase the balance of the recipient
        emit Deposited(_recipient, msg.value); // emit the event
    }

    /**
     * @notice Withdraw ETH from your balance
     * @param _amount The amount to withdraw
     */
    function withdraw(uint256 _amount) public {
        // TODO: Implement using checks-effects-interactions (CEI) pattern
        // WHY: CEI prevents reentrancy. Update state BEFORE external call so
        //      a re-entrant call sees the new balance and fails the check.
        // INVARIANT: balances[msg.sender] must reflect all prior deposits
        //      minus prior withdrawals. Never send ETH before updating it.
        //
        // CHECKS: 1) _amount > 0  2) balances[msg.sender] >= _amount
        // EFFECTS: 3) balances[msg.sender] -= _amount
        // INTERACTIONS: 4) msg.sender.call{value: _amount}("") 5) require success 6) emit
        require( _amount > 0, "Amount must be greater than 0"); // prevent reentrancy
        require( balances[msg.sender] >= _amount, "Insufficient balance"); // prevent reentrancy
        balances[msg.sender] -= _amount; // decrease the balance of the sender
        (bool success, ) = payable(msg.sender).call{value: _amount}(""); // send the ETH to the sender
        require(success, "Withdrawal failed"); // prevent reentrancy
        emit Withdrawn(msg.sender, _amount); // emit the event
    }

    /**
     * @notice Withdraw all your balance
     */
    function withdrawAll() public {
        // TODO: Implement
        // Use the same pattern as withdraw()
        uint256 amount = balances[msg.sender]; 
        require(amount > 0, "No balance to withdraw"); // prevent reentrancy
        
        balances[msg.sender] = 0; 
        // set the balance of the sender to 0
        (bool success, ) = payable(msg.sender).call{value: amount}(""); // send the ETH to the sender
        require(success, "Withdrawal failed"); // prevent reentrancy
        emit Withdrawn(msg.sender, amount);     // emit the event
    }

    /**
     * @notice Owner-only function to withdraw contract's unreserved funds
     * @param _amount Amount to withdraw
     */
    function ownerWithdraw(uint256 _amount) public {
        // TODO: Implement
        // 1. Require msg.sender == owner
        // 2. Calculate reserved funds (sum of all user balances conceptually)
        // 3. For simplicity, check contract balance >= _amount
        // 4. Send ETH to owner using .call
        // 5. Require success and emit Withdrawn event
        require(msg.sender == owner, "Only owner"); // prevent reentrancy
        require(_amount > 0, "Amount must be greater than 0"); // prevent reentrancy
        require(address(this).balance >= _amount, "Insufficient contract balance"); // prevent reentrancy
        (bool success, ) = payable(owner).call{value: _amount}(""); // send the ETH to the owner
        require(success, "Withdrawal failed"); // prevent reentrancy
        emit Withdrawn(owner, _amount); // emit the event
        
    }

    /**
     * @notice Get the balance of an address
     * @param _address The address to query
     * @return The balance
     */
    function getBalance(address _address) public view returns (uint256) {
        // TODO: Implement
        return balances[_address];
    }

    /**
     * @notice Get the contract's total ETH balance
     * @return The contract balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        // TODO: Implement
        // Return address(this).balance
        return address(this).balance;
    }

    /**
     * @notice Public function - callable from anywhere
     * @return A message string
     */
    function publicFunction() public pure returns (string memory) {
        // TODO: Return "This is public"
        return "This is public";
    }

    /**
     * @notice Wrapper to demonstrate calling internal function
     * @return The result from internal function
     */
    function callInternalFunction() public pure returns (string memory) {
        // TODO: Call and return result from internalFunction()
        return internalFunction();
    }

    /**
     * @notice Wrapper to demonstrate calling private function
     * @return The result from private function
     */
    function callPrivateFunction() public pure returns (string memory) {
        // TODO: Call and return result from privateFunction()
        return privateFunction();
    }

    // ============================================================
    // INTERNAL FUNCTIONS
    // ============================================================

    /**
     * @notice Internal function - callable from this contract and derived contracts
     * @return A message string
     */
    function internalFunction() internal pure returns (string memory) {
        // TODO: Return "This is internal"
        return "This is internal";
    }

    // ============================================================
    // PRIVATE FUNCTIONS
    // ============================================================

    /**
     * @notice Private function - only callable from this contract
     * @return A message string
     */
    function privateFunction() private pure returns (string memory) {
        // TODO: Return "This is private"
        return "This is private";
    }
}
