// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DatatypesStorage - CS50-Style Learning Contract
 * @notice Learn Solidity datatypes and EVM storage from first principles
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        WHAT IS THIS CONTRACT?
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This contract is your entry point into understanding how the Ethereum Virtual
 * Machine (EVM) actually stores and manipulates data. We're not just learning
 * Solidity syntax—we're building mental models of what happens at the machine level.
 *
 * Think of the EVM as a specialized computer with three main data locations:
 *
 * 1. STORAGE: The contract's permanent hard drive (persistent between transactions)
 * 2. MEMORY: Temporary RAM (cleared after each function call)
 * 3. CALLDATA: Read-only input data (function parameters from external calls)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    WHY DOES DATA LOCATION MATTER?
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * GAS COSTS (the real reason you care):
 *
 * - STORAGE writes: ~20,000 gas (cold) or ~5,000 gas (warm)
 * - MEMORY operations: ~3 gas per 256-bit word
 * - CALLDATA reads: ~3 gas per 256-bit word
 *
 * A single storage write costs the same as ~6,600 memory operations!
 * This is why understanding data location is critical for gas optimization.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    THE EVM AS A STACK MACHINE
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * At its core, the EVM is a STACK MACHINE that operates on 256-bit words.
 *
 * Think of it like a stack of plates:
 * - You can PUSH a value onto the top
 * - You can POP a value from the top
 * - Operations use values from the stack and put results back on the stack
 *
 * Every Solidity operation compiles down to EVM opcodes that manipulate this stack.
 *
 * For example, this Solidity:
 *     uint256 a = 5;
 *     uint256 b = 10;
 *     uint256 c = a + b;
 *
 * Becomes these EVM opcodes:
 *     PUSH1 0x05      // Push 5 onto stack
 *     PUSH1 0x0a      // Push 10 onto stack
 *     ADD             // Pop two values, add them, push result (15)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    STORAGE LAYOUT: 256-BIT SLOTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Storage is organized as a key-value store where:
 * - Keys are 256-bit slot numbers (0, 1, 2, ...)
 * - Values are 256-bit words
 *
 * State variables are assigned to slots SEQUENTIALLY at compile time:
 *
 *     uint256 number;      // Slot 0 (uses full 256 bits)
 *     address owner;       // Slot 1 (160 bits, but still uses full slot)
 *     bool isActive;       // Slot 2 (8 bits, but still uses full slot)
 *
 * This is WASTEFUL! Each SSTORE operation costs 20,000 gas, even if we only
 * use 8 bits of a 256-bit slot.
 *
 * STRUCT PACKING (the optimization):
 * If you declare variables that fit in one slot together, the Solidity compiler
 * will PACK them into the same slot:
 *
 *     address owner;       // 160 bits ─┐
 *     bool isActive;       //   8 bits  ├─ These three fit in ONE slot!
 *     uint88 extra;        //  88 bits ─┘   Total: 160+8+88 = 256 bits
 *
 * This saves gas! One SSTORE instead of three!
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    MAPPINGS: KECCAK-BASED ADDRESSING
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Mappings don't store data sequentially. Instead, they use HASH FUNCTIONS
 * to calculate storage locations:
 *
 *     mapping(address => uint256) public balances;  // Declared at slot 0
 *
 * To find the balance for address 0x1234...:
 *     slot = keccak256(abi.encode(0x1234..., 0))
 *          = keccak256(<address> || <mapping_slot>)
 *
 * This spreads values across the 2^256 storage address space, preventing collisions.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                    DYNAMIC ARRAYS: LENGTH + DATA REGION
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Dynamic arrays use TWO storage regions:
 *
 *     uint256[] numbers;  // Declared at slot 3
 *
 * Slot 3 stores: The LENGTH of the array
 * Data starts at: keccak256(abi.encode(3))
 *
 * So array[0] is at slot keccak256(3)
 *    array[1] is at slot keccak256(3) + 1
 *    array[2] is at slot keccak256(3) + 2
 *    ...and so on
 *
 * LEARNING GOALS:
 * 1. Understand value types vs. reference types at the EVM level
 * 2. Master storage, memory, and calldata - what they are and when to use each
 * 3. Learn storage slot layout and struct packing
 * 4. Understand how mappings and arrays use keccak256 for addressing
 * 5. Build intuition for gas costs of different operations
 */
contract DatatypesStorage {
    // ════════════════════════════════════════════════════════════════════════
    // TYPE DECLARATIONS: STRUCT LAYOUT IN THE EVM
    // ════════════════════════════════════════════════════════════════════════
    //
    // WHAT IS A STRUCT?
    // ------------------
    // A struct is a COMPOSITE DATA TYPE that groups related data together.
    // Think of it like a C struct or a class without methods.
    //
    // IN MEMORY TERMS:
    // ----------------
    // When a struct is stored in storage, its fields are laid out SEQUENTIALLY
    // starting from the struct's base slot, just like state variables.
    //
    // CRITICAL DIFFERENCE: Structs vs. Simple Types
    // ----------------------------------------------
    // When you write:
    //     uint256 number;
    //
    // You're creating a VALUE. Reading `number` loads the actual uint256 from storage.
    //
    // When you write:
    //     User storage user = users[msg.sender];
    //
    // You're creating a REFERENCE (like a pointer in C). `user` points to storage,
    // it doesn't copy the data. Modifying `user.balance` modifies storage directly!
    //
    // THIS IS NOT A COPY! Think of it like:
    //     User* user = &users[msg.sender];  // C-style pointer analogy
    //
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice UNPACKED STRUCT: User data structure (NOT gas-optimized)
     * @dev This struct demonstrates the DEFAULT storage layout without packing
     *
     * STORAGE LAYOUT FOR User (when stored in mapping at slot S):
     * ────────────────────────────────────────────────────────────────────────
     * Slot S+0: wallet (address, 160 bits)    [WASTES 96 bits!]
     * Slot S+1: balance (uint256, 256 bits)   [Fully utilized]
     * Slot S+2: isRegistered (bool, 8 bits)   [WASTES 248 bits!]
     * ────────────────────────────────────────────────────────────────────────
     * TOTAL: 3 storage slots = 3 SSTOREs to write = ~60,000 gas
     *
     * WHAT'S HAPPENING AT THE EVM LEVEL:
     * -----------------------------------
     * When you access users[0x1234...].wallet, the EVM:
     * 1. Calculates mapping slot: keccak256(0x1234... || mapping_slot)
     * 2. Loads that slot (SLOAD opcode, ~100-2100 gas depending on warm/cold)
     * 3. Masks off the top 96 bits (address is only 160 bits)
     *
     * WHY NO PACKING?
     * ---------------
     * Fields don't fit together in 256 bits:
     * - address (160) + uint256 (256) = 416 bits > 256 bits  ❌
     * - uint256 (256) + bool (8) = 264 bits > 256 bits       ❌
     */
    struct User {
        address wallet;       // 160 bits, uses ENTIRE slot (slot S+0)
        uint256 balance;      // 256 bits, uses ENTIRE slot (slot S+1)
        bool isRegistered;    // 8 bits, uses ENTIRE slot (slot S+2)
    }

    /**
     * @notice PACKED STRUCT: Gas-optimized data structure
     * @dev This struct demonstrates OPTIMAL PACKING to minimize storage costs
     *
     * STORAGE LAYOUT FOR PackedData (when stored at slot P):
     * ────────────────────────────────────────────────────────────────────────
     * Slot P+0:
     *   ├─ smallNumber1 (uint128, bits 0-127)
     *   └─ smallNumber2 (uint128, bits 128-255)
     *   Total: 256 bits (PERFECT FIT!)
     *
     * Slot P+1:
     *   ├─ user (address, bits 0-159)     = 160 bits
     *   ├─ timestamp (uint64, bits 160-223) = 64 bits
     *   └─ flag (bool, bit 224)             = 8 bits
     *   Total: 232 bits used, 24 bits unused  (ACCEPTABLE!)
     * ────────────────────────────────────────────────────────────────────────
     * TOTAL: 2 storage slots = 2 SSTOREs to write = ~40,000 gas
     *
     * GAS SAVINGS:
     * ------------
     * Unpacked: 3 slots × 20,000 gas = 60,000 gas
     * Packed:   2 slots × 20,000 gas = 40,000 gas
     * SAVINGS:  20,000 gas (33% reduction!)
     *
     * WHAT THE EVM ACTUALLY DOES:
     * ----------------------------
     * When you write: packedData.timestamp = block.timestamp;
     *
     * The EVM must:
     * 1. SLOAD slot P+1 (~100-2100 gas)
     * 2. Mask off bits 160-223 (clear old timestamp)
     * 3. Shift new timestamp value to bits 160-223
     * 4. OR the new value with the existing slot data
     * 5. SSTORE slot P+1 back (~5,000-20,000 gas)
     *
     * This is called READ-MODIFY-WRITE and it's more expensive than writing
     * a full slot, BUT still cheaper than using a whole new slot!
     *
     * PACKING RULES:
     * --------------
     * 1. Order fields from largest to smallest
     * 2. Group fields that sum to ≤ 256 bits
     * 3. uint128 + uint128 = PERFECT (256 bits exactly)
     * 4. address (160) + uint64 (64) + bool (8) = 232 bits (close enough!)
     */
    struct PackedData {
        uint128 smallNumber1;    // 128 bits (slot P+0, bits 0-127)
        uint128 smallNumber2;    // 128 bits (slot P+0, bits 128-255)
        address user;            // 160 bits (slot P+1, bits 0-159)
        uint64 timestamp;        // 64 bits  (slot P+1, bits 160-223)
        bool flag;               // 8 bits   (slot P+1, bit 224)
    }

    // ════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES: CONTRACT STORAGE LAYOUT
    // ════════════════════════════════════════════════════════════════════════
    //
    // STATE VARIABLES ARE STORED IN STORAGE (PERSISTENT ACROSS TRANSACTIONS)
    //
    // Each state variable is assigned a STORAGE SLOT at compile time.
    // Slots are numbered sequentially starting from 0.
    //
    // ACTUAL STORAGE LAYOUT FOR THIS CONTRACT:
    // ─────────────────────────────────────────────────────────────────────────
    // Slot 0: number    (uint256, 256 bits)  - FULL SLOT
    // Slot 1: owner     (address, 160 bits)  - WASTED 96 bits!
    // Slot 2: isActive  (bool, 8 bits)       - WASTED 248 bits!
    // Slot 3: data      (bytes32, 256 bits)  - FULL SLOT
    // Slot 4: message   (string, dynamic)    - Stores LENGTH, data elsewhere
    // Slot 5: balances  (mapping)            - Doesn't store here, uses keccak256
    // Slot 6: numbers   (array)              - Stores LENGTH, data elsewhere
    // Slot 7: users     (mapping)            - Doesn't store here, uses keccak256
    // ─────────────────────────────────────────────────────────────────────────
    //
    // OPTIMIZATION NOTE:
    // If we reordered as: uint256, bytes32, address, bool...
    // We could pack address+bool into ONE slot, saving 20,000 gas per deployment!
    //
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @dev VALUE TYPE: uint256 (Unsigned 256-bit Integer)
     *
     * STORAGE LOCATION: Slot 0
     *
     * WHY uint256 IS THE DEFAULT:
     * ---------------------------
     * The EVM is a 256-bit machine. ALL operations work on 256-bit words.
     * Using uint256 is the MOST GAS-EFFICIENT integer type because:
     * - No need to mask/truncate values
     * - Direct stack operations
     * - No extra opcodes for size conversion
     *
     * ALTERNATIVES:
     * -------------
     * - uint8, uint16, uint32... uint256 (8-bit increments)
     * - int8, int16, int32... int256 (signed versions)
     *
     * WHEN TO USE SMALLER TYPES:
     * ---------------------------
     * ONLY when packing multiple values into one storage slot!
     * Otherwise, smaller types are MORE expensive due to extra masking operations.
     *
     * Example:
     *     uint8 x = 5;      // Still uses 256 bits in storage
     *                       // PLUS extra gas to mask to 8 bits!
     *
     * EVM OPERATIONS:
     * ---------------
     * Reading: SLOAD <slot_0> → Pushes 256-bit value onto stack
     * Writing: SSTORE <slot_0> <value> → Writes 256-bit value to storage
     */
    uint256 public number;

    /**
     * @dev VALUE TYPE: address (160-bit Ethereum Address)
     *
     * STORAGE LOCATION: Slot 1
     *
     * WHAT IS AN ADDRESS?
     * -------------------
     * An address is a 160-bit (20-byte) identifier for an Ethereum account.
     * It can be:
     * - An externally owned account (EOA) controlled by a private key
     * - A contract account controlled by code
     *
     * address vs. address payable:
     * ----------------------------
     * - address: Can receive ETH via transfer/send, but NOT directly
     * - address payable: Can receive ETH directly via .transfer() or .send()
     *
     * To convert: payable(someAddress)
     *
     * STORAGE WASTE:
     * --------------
     * This uses a FULL 256-bit slot but only uses 160 bits!
     * Wasted: 96 bits = 12 bytes
     *
     * If we packed this with `bool isActive` (next variable), we'd save
     * 20,000 gas on deployment!
     */
    address public owner;

    /**
     * @dev VALUE TYPE: bool (Boolean - True or False)
     *
     * STORAGE LOCATION: Slot 2
     *
     * DEFAULT VALUE IN STORAGE:
     * -------------------------
     * All storage starts initialized to ZERO.
     * For bool: 0 = false, 1 = true
     * So the default value for any bool in storage is FALSE.
     *
     * STORAGE EFFICIENCY:
     * -------------------
     * A bool only needs 1 BIT (true/false), but it uses a FULL 256-bit slot!
     * This wastes 255 bits.
     *
     * BETTER APPROACH (if we cared about gas):
     * -----------------------------------------
     * Reorder state variables:
     *     address public owner;     // 160 bits
     *     bool public isActive;     // 8 bits
     * These would pack into ONE slot (160 + 8 = 168 < 256)
     *
     * EVM REPRESENTATION:
     * -------------------
     * false = 0x0000...0000
     * true  = 0x0000...0001
     */
    bool public isActive;

    /**
     * @dev VALUE TYPE: bytes32 (Fixed-Size Byte Array, 32 bytes)
     *
     * STORAGE LOCATION: Slot 3
     *
     * WHEN TO USE bytes32:
     * --------------------
     * 1. Storing hashes (keccak256 output is bytes32)
     * 2. Fixed-length data that fits in 32 bytes
     * 3. Gas-efficient alternative to string for short data
     *
     * bytes32 vs. string vs. bytes:
     * -----------------------------
     * - bytes32: FIXED size (32 bytes exactly), stored in ONE slot
     * - string: DYNAMIC size, stored as length + data (multiple slots)
     * - bytes: DYNAMIC size, stored as length + data (multiple slots)
     *
     * GAS COMPARISON:
     * ---------------
     * Storing "hello" (5 characters):
     * - As bytes32: ~20,000 gas (1 SSTORE)
     * - As string:  ~43,000 gas (length + data SSTOREs)
     *
     * Use bytes32 when you can! It's MUCH cheaper.
     */
    bytes32 public data;

    /**
     * @dev REFERENCE TYPE: string (Dynamic UTF-8 String)
     *
     * STORAGE LOCATION: Slot 4 (stores LENGTH), data at keccak256(4)
     *
     * WHY ARE STRINGS EXPENSIVE?
     * --------------------------
     * Strings are DYNAMIC, meaning their length isn't known at compile time.
     *
     * STORAGE LAYOUT FOR STRINGS:
     * ---------------------------
     * Short strings (< 32 bytes):
     *   Slot 4: (length * 2) | data
     *   Everything fits in one slot!
     *
     * Long strings (≥ 32 bytes):
     *   Slot 4: (length * 2 + 1)
     *   Data starts at: keccak256(4), keccak256(4)+1, keccak256(4)+2, ...
     *
     * Example: Storing "Hello, World!" (13 characters)
     *   Slot 4 = 0x48656c6c6f2c20576f726c64211a
     *            └─ data ─────────────────┘└─ length*2 = 26
     *
     * COST IMPLICATIONS:
     * ------------------
     * Every 32 bytes of string data = 1 extra SSTORE = +20,000 gas
     */
    string public message;

    /**
     * @dev REFERENCE TYPE: mapping(address => uint256)
     *
     * STORAGE LOCATION: Slot 5 (NEVER actually used!)
     *
     * HOW MAPPINGS WORK:
     * ------------------
     * Mappings DON'T store data at their declared slot.
     * Instead, they use KECCAK256 hashing to calculate storage locations:
     *
     * To find balances[0x1234...]:
     *     slot = keccak256(abi.encode(0x1234..., 5))
     *
     * This means:
     * - Every key maps to a UNIQUE slot in the 2^256 storage space
     * - No collisions (cryptographically impossible with keccak256)
     * - No way to iterate over all keys (they're scattered everywhere!)
     *
     * WHAT HAPPENS FOR NON-EXISTENT KEYS:
     * ------------------------------------
     * If you access a key that was never set:
     *     uint256 bal = balances[someAddress];
     *
     * The EVM:
     * 1. Calculates slot = keccak256(abi.encode(someAddress, 5))
     * 2. Loads that slot with SLOAD
     * 3. Returns 0 (all storage is zero-initialized)
     *
     * This is why balances[nonExistentAddress] returns 0, not an error!
     *
     * GAS FOR MAPPINGS:
     * -----------------
     * Read (SLOAD): ~100 gas (warm) or ~2,100 gas (cold)
     * Write (SSTORE): ~5,000 gas (warm) or ~20,000 gas (cold)
     */
    mapping(address => uint256) public balances;

    /**
     * @dev REFERENCE TYPE: uint256[] (Dynamic Array)
     *
     * STORAGE LOCATION: Slot 6 (stores LENGTH), data starts at keccak256(6)
     *
     * DYNAMIC ARRAY STORAGE LAYOUT:
     * -----------------------------
     * Slot 6: LENGTH of the array (number of elements)
     * Slot keccak256(6)+0: numbers[0]
     * Slot keccak256(6)+1: numbers[1]
     * Slot keccak256(6)+2: numbers[2]
     * ... and so on
     *
     * EXAMPLE:
     * --------
     * If we push three numbers [42, 100, 200]:
     *
     * Slot 6 = 3 (length)
     * Slot keccak256(6)+0 = 42
     * Slot keccak256(6)+1 = 100
     * Slot keccak256(6)+2 = 200
     *
     * GAS IMPLICATIONS:
     * -----------------
     * .push(value):
     *   - SLOAD slot 6 (read length)          ~100-2,100 gas
     *   - SSTORE slot 6 (increment length)    ~5,000-20,000 gas
     *   - SSTORE keccak256(6)+length (data)   ~20,000 gas
     *   TOTAL: ~25,000-42,000 gas per push!
     *
     * .pop():
     *   - SLOAD slot 6 (read length)          ~100-2,100 gas
     *   - SSTORE slot 6 (decrement length)    ~5,000 gas
     *   - SSTORE keccak256(6)+length (zero)   ~5,000 gas (refund!)
     *   TOTAL: ~10,000-12,000 gas per pop
     *
     * Arrays are EXPENSIVE! Use them only when necessary.
     */
    uint256[] public numbers;

    /**
     * @dev REFERENCE TYPE: mapping(address => User)
     *
     * STORAGE LOCATION: Slot 7 (NEVER actually used!)
     *
     * NESTED STRUCT IN MAPPING:
     * -------------------------
     * For users[0x1234...], the EVM calculates:
     *     base_slot = keccak256(abi.encode(0x1234..., 7))
     *
     * Then the struct fields are laid out sequentially:
     *     Slot base_slot+0: wallet
     *     Slot base_slot+1: balance
     *     Slot base_slot+2: isRegistered
     *
     * STORAGE REFERENCES:
     * -------------------
     * When you write:
     *     User storage user = users[msg.sender];
     *
     * You're creating a POINTER to storage, not a copy!
     * Any modification to `user` modifies storage directly.
     *
     * MISCONCEPTION CALLOUTS (CLAUDE/.cursorrules requirement):
     * ----------------------------------------------------------
     * • This does NOT copy storage. `user` is a reference to the storage slot.
     * • Modifying `user.balance` writes directly to persistent storage.
     * • For `User memory user = users[msg.sender]`: This DOES copy to memory.
     *   Memory is temporary; it does NOT persist after the call ends.
     * • calldata is read-only and does NOT allocate new storage or memory.
     *
     * THIS IS CRITICAL TO UNDERSTAND!
     * --------------------------------
     * User storage user = users[msg.sender];  // REFERENCE (pointer)
     * user.balance = 100;                     // Modifies storage!
     *
     * vs.
     *
     * User memory user = users[msg.sender];   // COPY to memory
     * user.balance = 100;                     // Modifies memory only!
     *
     * Think of `storage` like `*` in C, and `memory` like pass-by-value.
     */
    mapping(address => User) public users;

    // ============================================================
    // EVENTS
    // ============================================================

    // TODO: Declare an event 'NumberUpdated' that logs the old and new number value.
    // Why are events useful for off-chain applications?
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    // TODO: Declare an event 'UserRegistered' that logs the user's wallet and balance.
    event UserRegistered(address indexed wallet, uint256 balance);
    // TODO: Declare an event 'FundsDeposited' that logs the depositor and the amount.
    event FundsDeposited(address indexed depositor, uint256 amount);
    // TODO: Declare an event 'MessageUpdated' that logs the old and new message.
    event MessageUpdated(string oldMessage, string newMessage);
    // TODO: Declare an event 'BalanceUpdated' that logs the address and the balance.
    event BalanceUpdated(address addr, uint256 balance);
    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    // TODO: Implement the constructor.
    // It should set the 'owner' to the address that deployed the contract (msg.sender).
    // It should also set 'isActive' to true.
    constructor() {
        owner = msg.sender;
        isActive = true;
    }

    // ============================================================
    // ETHER HANDLING
    // ============================================================

    /**
     * @notice Allows users to deposit ETH into the contract.
     * @dev This function should be payable. The sent ETH should be added to the sender's balance.
     */
    function deposit() public payable {
        // TODO: Implement this payable function.
        // 1. Check if msg.value is greater than 0.
        // 2. Add the sent ETH (msg.value) to the sender's balance in the 'balances' mapping.
        // 3. Emit a 'FundsDeposited' event.
        require(msg.value > 0, "Amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // ============================================================
    // VALUE & REFERENCE TYPE FUNCTIONS
    // ============================================================

    /**
     * @notice Set the 'number' state variable.
     * @param _number The new number value.
     */
    function setNumber(uint256 _number) public {
        // TODO: Implement this function.
        // 1. Store the old number in a temporary variable.
        // 2. Update the 'number' state variable to _number.
        // 3. Emit the 'NumberUpdated' event with the old and new values.
        uint256 oldValue = number;
        number = _number;
        emit NumberUpdated(oldValue, _number);
    }

    /**
     * @notice Get the current value of 'number'.
     * @return The current number value.
     */
    function getNumber() public view returns (uint256) {
        // TODO: Implement to return the 'number' state variable.
        return number;
    }

    /**
     * @notice Increment the 'number' by 1.
     * @dev What happens if 'number' is at its maximum value (type(uint256).max)?
     */
    function incrementNumber() public {
        // TODO: Implement to increment 'number'.
        number += 1;
    }

    /**
     * @notice Set the 'message' state variable.
     * @param _message The new message.
     */
    function setMessage(string memory _message) public {
        // TODO: Implement to update the 'message' state variable.
        string memory oldMessage = message;
        message = _message;
        emit MessageUpdated(oldMessage, _message);
    }

    // ============================================================
    // MAPPING FUNCTIONS
    // ============================================================

    /**
     * @notice Set the balance for a specific address.
     * @param _addr The address to set the balance for.
     * @param _balance The balance amount.
     */
    function setBalance(address _addr, uint256 _balance) public {
        // TODO: Implement using the 'balances' mapping.
        balances[_addr] = _balance;
        emit BalanceUpdated(_addr, _balance);
    }

    /**
     * @notice Get the balance for a specific address.
     * @param _addr The address to query.
     * @return The balance amount.
     */
    function getBalance(address _addr) public view returns (uint256) {
        // TODO: Implement to return the balance from the 'balances' mapping.
        return balances[_addr];
    }

    // ============================================================
    // ARRAY FUNCTIONS
    // ============================================================

    /**
     * @notice Add a number to the 'numbers' array.
     * @param _number The number to add.
     */
    function addNumber(uint256 _number) public {
        // TODO: Implement using array's 'push' method.
        numbers.push(_number);
    }

    /**
     * @notice Get the length of the 'numbers' array.
     * @return The array length.
     */
    function getNumbersLength() public view returns (uint256) {
        // TODO: Implement to return the array's length.
        return numbers.length;
    }

    /**
     * @notice Get a number at a specific index in the 'numbers' array.
     * @param _index The index to query.
     * @return The number at that index.
     */
    function getNumberAt(uint256 _index) public view returns (uint256) {
        // TODO: Implement with a bounds check to prevent errors.
        // Use a require() statement.
        require(_index < numbers.length, "Index out of bounds");
        return numbers[_index];
    }

    /**
     * @notice Remove a number at a specific index from the 'numbers' array.
     * @dev This is a complex operation. How do you remove an element and keep the array packed?
     *      Hint: You may need to shift elements.
     * @param _index The index of the element to remove.
     */
    function removeNumber(uint256 _index) public {
        // TODO: Advanced - Implement this function.
        // 1. Check if the index is valid.
        // 2. Move the last element to the place of the one to be removed.
        // 3. Remove the last element of the array.
        require(_index < numbers.length, "Index out of bounds");
        uint256 lastIndex = numbers.length - 1;
        numbers[_index] = numbers[lastIndex];
        numbers.pop();
    }

    // ============================================================
    // STRUCT FUNCTIONS
    // ============================================================

    /**
     * @notice Register a new user.
     * @param _wallet The user's wallet address.
     * @param _balance The initial balance.
     */
    function registerUser(address _wallet, uint256 _balance) public {
        // TODO: Create a User struct in the 'users' mapping.
        // Set 'isRegistered' to true.
        // Emit the 'UserRegistered' event.
        users[_wallet] = User({
            wallet: _wallet,
            balance: _balance,
            isRegistered: true
        });
        emit UserRegistered(_wallet, _balance);
    }

    /**
     * @notice Get user information.
     * @param _wallet The user's wallet address.
     * @return wallet The user's wallet address.
     * @return balance The user's balance.
     * @return isRegistered The user's registration status.
     */
    function getUser(address _wallet)
        public
        view
        returns (address wallet, uint256 balance, bool isRegistered)
    {
        // TODO: Implement to return data from the 'users' mapping.
        // What does this function return for a non-existent user?
        return (users[_wallet].wallet, users[_wallet].balance, users[_wallet].isRegistered);
    }

    // ============================================================
    // DATA LOCATION DEMONSTRATION
    // ============================================================

    /**
     * @notice Demonstrates 'memory' usage. This function sums an array without affecting storage.
     * @param _arr The array to process (passed in memory).
     * @return The sum of the array elements.
     */
    function sumMemoryArray(uint256[] memory _arr) public pure returns (uint256) {
        // TODO: Implement the sum of the array.
        uint256 sum = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            sum += _arr[i];
        }
        return sum;
        // Why is this function 'pure'? What's the difference between 'view' and 'pure'?
    }

    /**
     * @notice Demonstrates 'calldata' usage. It's read-only and gas-efficient.
     * @param _arr The array to process (passed in calldata).
     * @return The first element of the array.
     *
     * MISCONCEPTION CALLOUTS:
     * • calldata does NOT allocate memory. It's a zero-copy read-only view of tx input.
     * • calldata does NOT persist after the call. It exists only during execution.
     * • calldata is cheaper than memory because no copy occurs—we read directly from tx data.
     * • This function can be 'pure' because we only read calldata (no storage).
     */
    function getFirstElement(uint256[] calldata _arr) public pure returns (uint256) {
        // TODO: Implement to return the first element.
        require(_arr.length > 0, "Array is empty");
        return _arr[0];
    }

    // ============================================================
    // HELPER FUNCTIONS
    // ============================================================

    /**
     * @notice Checks if an address has a non-zero balance.
     * @param _addr The address to check.
     * @return True if the balance is greater than 0, false otherwise.
     */
    function hasBalance(address _addr) public view returns (bool) {
        // TODO: Implement this helper function.
        return balances[_addr] > 0;
    }
}
