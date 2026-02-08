// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title UpgradeableProxySolution
 * @notice UUPS proxy pattern enabling contract upgradeability
 * 
 * PURPOSE: Separate logic (upgradeable) from state (persistent) - enables bug fixes/upgrades
 * CS CONCEPTS: Delegation pattern, storage layout separation, fallback functions
 * 
 * CONNECTIONS:
 * - Project 01: EIP-1967 storage slots (keccak256-based, like mappings)
 * - Project 02: delegatecall (executes code in proxy's context)
 * - Project 04: Access control for upgrades
 * 
 * HOW IT WORKS: User → Proxy fallback() → delegatecall → Implementation → State in proxy
 *
 * Delegatecall executes code from another contract in current contract's context.
 * This is THE key mechanism that makes proxies work!
 */
contract UpgradeableProxySolution {
    // ════════════════════════════════════════════════════════════════════════
    // EIP-1967 STORAGE SLOTS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice EIP-1967 storage slot for implementation address
     * @dev Calculated as: keccak256("eip1967.proxy.implementation") - 1
     *      The -1 prevents collisions with implementation storage slots
     *      
     *      WHY THIS SLOT?
     *      - Unlikely to collide with implementation storage
     *      - Standardized across all proxy implementations
     *      - Tools can read this slot easily
     *      
     *      CONNECTION TO PROJECT 01: Storage slot calculation!
     *      Uses keccak256 just like mapping storage slots
     */
    bytes32 private immutable implementationSlot = 
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    
    /**
     * @notice EIP-1967 storage slot for admin address
     * @dev Calculated as: keccak256("eip1967.proxy.admin") - 1
     *      Stores who can upgrade the implementation
     */
    bytes32 private immutable adminSlot =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    
    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Deploy proxy with initial implementation
     * @param _implementation Address of initial implementation contract
     *
     * @dev PROXY INITIALIZATION: Setting Up the Proxy
     * ═══════════════════════════════════════════════
     *
     *      This constructor sets up the proxy with an initial implementation.
     *      The deployer becomes the admin (can upgrade later).
     *
     *      EXECUTION FLOW:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. SET IMPLEMENTATION: Store address    │
     *      │    - Uses EIP-1967 slot                 │
     *      │    ↓                                      │
     *      │ 2. SET ADMIN: Store deployer as admin   │
     *      │    - Uses EIP-1967 slot                 │
     *      └─────────────────────────────────────────┘
     *
     *      STORAGE LAYOUT:
     *      ┌─────────────────────────────────────────────┐
     *      │ Slot: keccak256("eip1967.proxy.implementation") - 1│
     *      │ Value: Implementation contract address      │
     *      ├─────────────────────────────────────────────┤
     *      │ Slot: keccak256("eip1967.proxy.admin") - 1 │
     *      │ Value: Admin address (deployer)             │
     *      └─────────────────────────────────────────────┘
     *
     *      REAL-WORLD ANALOGY:
     *      Like setting up a building with initial electrical system:
     *      - **Implementation** = Initial electrical system
     *      - **Admin** = Building manager (can upgrade system)
     */
    constructor(address _implementation) {
        _setImplementation(_implementation);
        _setAdmin(msg.sender);
    }

    // ════════════════════════════════════════════════════════════════════════
    // INTERNAL FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set implementation address
     * @param newImplementation Address of new implementation contract
     *
     * @dev IMPLEMENTATION SETTER: Updating the Logic Contract
     * ═══════════════════════════════════════════════════════
     *
     *      This function stores the implementation address in the EIP-1967 slot.
     *      Uses assembly for direct storage access (gas-efficient).
     *
     *      SECURITY: Checks that address has code (is a contract)
     *      Prevents setting EOA (Externally Owned Account) as implementation.
     */
    function _setImplementation(address newImplementation) private {
        require(newImplementation.code.length > 0, "Not a contract");
        assembly {
            sstore(implementationSlot, newImplementation)
        }
    }
    
    /**
     * @notice Set admin address
     * @param newAdmin Address of new admin
     *
     * @dev ADMIN SETTER: Updating the Admin
     * ═══════════════════════════════════════
     *
     *      Stores admin address in EIP-1967 slot.
     *      Admin can upgrade implementation (in full UUPS, upgrade function in implementation).
     */
    function _setAdmin(address newAdmin) private {
        assembly {
            sstore(adminSlot, newAdmin)
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get current implementation address
     * @return impl Address of implementation contract
     *
     * @dev IMPLEMENTATION GETTER: Reading EIP-1967 Slot
     * ══════════════════════════════════════════════════
     *
     *      Reads implementation address from EIP-1967 storage slot.
     *      Uses assembly for direct storage access.
     */
    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(implementationSlot)
        }
    }
    
    /**
     * @notice Get admin address
     * @return adm Address of admin
     *
     * @dev ADMIN GETTER: Reading EIP-1967 Slot
     * ═════════════════════════════════════════
     *
     *      Reads admin address from EIP-1967 storage slot.
     */
    function admin() public view returns (address adm) {
        assembly {
            adm := sload(adminSlot)
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // FALLBACK FUNCTION (THE HEART OF THE PROXY)
    // ════════════════════════════════════════════════════════════════════════

    /**
     * @notice Fallback function that delegates all calls to implementation
     *
     * @dev DELEGATECALL FALLBACK: The Proxy Mechanism
     * ═════════════════════════════════════════════════
     *
     *      This is THE function that makes proxies work! It catches all calls
     *      to functions that don't exist in the proxy and delegates them to
     *      the implementation contract.
     *
     *      HOW DELEGATECALL WORKS:
     *      ┌─────────────────────────────────────────┐
     *      │ 1. GET IMPLEMENTATION: Read from slot    │
     *      │    ↓                                      │
     *      │ 2. COPY CALLDATA: Copy function call     │
     *      │    ↓                                      │
     *      │ 3. DELEGATECALL: Execute implementation  │
     *      │    - Uses proxy's storage                │
     *      │    - Uses proxy's balance                │
     *      │    - Uses proxy's address (msg.sender)   │
     *      │    ↓                                      │
     *      │ 4. COPY RETURNDATA: Get return value     │
     *      │    ↓                                      │
     *      │ 5. RETURN OR REVERT: Forward result      │
     *      └─────────────────────────────────────────┘
     *
     *      CONNECTION TO PROJECT 02: Delegatecall!
     *      ══════════════════════════════════════════
     *
     *      Delegatecall executes code from another contract in current context:
     *      - Code runs from implementation
     *      - Storage changes happen in proxy
     *      - This enables upgradeability!
     *
     *      ASSEMBLY BREAKDOWN:
     *      - calldatacopy(0, 0, calldatasize()): Copy call data to memory
     *      - delegatecall(...): Execute implementation code
     *      - returndatacopy(...): Copy return data
     *      - switch result: Handle success/failure
     *
     *      REAL-WORLD ANALOGY:
     *      Like a receptionist forwarding calls:
     *      - **Call comes in** = Function call to proxy
     *      - **Forward to expert** = Delegatecall to implementation
     *      - **Expert works in your office** = Code executes in proxy context
     *      - **Return answer** = Forward return value
     *
     *      🎓 LEARNING MOMENT:
     *      This fallback function is what makes EVERY proxy call work!
     *      Without it, calls to implementation functions would revert.
     *      Understanding delegatecall is CRITICAL for proxy patterns!
     */
    fallback() external payable {
        address impl = implementation();
        assembly {
            // Copy call data to memory (starting at position 0)
            calldatacopy(0, 0, calldatasize())
            
            // Delegatecall to implementation
            // - gas(): Forward all remaining gas
            // - impl: Implementation contract address
            // - 0, calldatasize(): Memory location and size of call data
            // - 0, 0: Return data location and size (we'll copy it separately)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy return data to memory
            returndatacopy(0, 0, returndatasize())
            
            // Handle result
            switch result
            case 0 {
                // Delegatecall failed, revert with return data
                revert(0, returndatasize())
            }
            default {
                // Delegatecall succeeded, return data
                return(0, returndatasize())
            }
        }
    }
    
    /**
     * @notice Receive function for plain ETH transfers
     * @dev Allows proxy to receive ETH
     *      CONNECTION TO PROJECT 02: receive() function!
     */
    receive() external payable {}
}

// ═══════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION CONTRACTS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * @title ImplementationV1
 * @notice First version of implementation contract
 * @dev ⚠️  CRITICAL: Storage layout must be preserved in V2!
 *
 * STORAGE LAYOUT:
 * - Slot 0: value (uint256)
 *
 * This layout MUST NOT CHANGE in V2! Only add new variables at the end.
 */
contract ImplementationV1 {
    uint256 public value;  // Slot 0 - MUST stay in slot 0!
    
    function setValue(uint256 _value) public {
        value = _value;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}

/**
 * @title ImplementationV2
 * @notice Second version with new functionality
 * @dev ⚠️  CRITICAL: Storage layout compatibility!
 *
 * STORAGE LAYOUT (MUST MATCH V1):
 * - Slot 0: value (uint256) - SAME AS V1!
 *
 * ✅ CORRECT: value stays in slot 0
 * ✅ CORRECT: New functions added (doesn't affect storage)
 * ❌ WRONG: Would be changing value to slot 1
 *
 * REAL-WORLD ANALOGY:
 * Like upgrading software - new features added, but data format stays compatible!
 */
contract ImplementationV2 {
    uint256 public value;  // Slot 0 - SAME AS V1! (Critical!)
    
    function setValue(uint256 _value) public {
        value = _value * 2;  // New logic, but storage layout unchanged
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
    
    /**
     * @notice New function in V2
     * @dev This is fine - new functions don't affect storage layout
     *      Only storage variable order matters!
     */
    function newFunction() public pure returns (string memory) {
        return "This is V2";
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. PROXIES ENABLE UPGRADEABILITY
 *    ✅ Separate logic (implementation) from state (proxy)
 *    ✅ Proxy stores state, implementation contains logic
 *    ✅ Can upgrade implementation while preserving state
 *    ✅ Real-world: Building with replaceable wiring
 *
 * 2. DELEGATECALL IS THE KEY MECHANISM
 *    ✅ Executes code from another contract in current context
 *    ✅ Uses proxy's storage, balance, and address
 *    ✅ Enables upgradeability without redeployment
 *    ✅ Real-world: Hiring consultant who works in your office
 *
 * 3. EIP-1967 STORAGE SLOTS PREVENT COLLISIONS
 *    ✅ Standardized slots for implementation and admin
 *    ✅ Calculated as keccak256("eip1967.proxy.*") - 1
 *    ✅ Unlikely to collide with implementation storage
 *    ✅ Tools can read these slots easily
 *
 * 4. STORAGE LAYOUT COLLISIONS ARE DANGEROUS
 *    ✅ Changing storage variable order corrupts data
 *    ✅ Always add new variables at the end
 *    ✅ Never change existing variable positions
 *    ✅ Document storage layout carefully
 *
 * 5. FALLBACK FUNCTION DELEGATES ALL CALLS
 *    ✅ Catches calls to non-existent functions
 *    ✅ Delegates to implementation via delegatecall
 *    ✅ Forwards return data or reverts
 *    ✅ This is what makes proxies work!
 *
 * 6. INITIALIZATION PATTERN VS CONSTRUCTOR
 *    ✅ Constructors don't work in proxies (delegatecall context)
 *    ✅ Use initializer functions instead
 *    ✅ Protect initializers with onlyInitializer modifier
 *    ✅ Call initializer after proxy deployment
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Changing storage layout order (corrupts data!)
 * ❌ Using constructor in implementation (doesn't work with delegatecall)
 * ❌ Not using EIP-1967 slots (storage collisions)
 * ❌ Not checking implementation has code (can set EOA)
 * ❌ Not handling return data correctly in fallback
 * ❌ Forgetting to preserve storage layout in upgrades
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study OpenZeppelin upgradeable contracts
 * • Understand transparent vs UUPS patterns
 * • Learn about initialization vs constructors
 * • Explore proxy admin patterns
 * • Move to Project 11 to learn about ERC4626 vaults
 */
