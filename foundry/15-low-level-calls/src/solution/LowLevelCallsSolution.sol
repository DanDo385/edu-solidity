// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LowLevelCallsSolution
 * @notice Low-level call operations: call, delegatecall, staticcall
 * 
 * PURPOSE: Understanding EVM call mechanisms and their security implications
 * CS CONCEPTS: Message passing, execution context, call vs delegatecall
 * 
 * CONNECTIONS:
 * - Project 02: .call{value:}() for ETH transfers
 * - Project 10: delegatecall for proxy patterns
 * - Project 14: ABI encoding for call data
 * 
 * KEY: call (target context) vs delegatecall (caller context) - critical difference!
 */
contract TargetContract {
    uint256 public value;
    address public sender;
    uint256 public receivedValue;

    event ValueSet(uint256 newValue, address setter);
    event ValueReceived(uint256 amount, address from);

    error CustomError(string message);

    /**
     * @notice Sets value and records the sender
     * @param _value New value to set
     */
    function setValue(uint256 _value) public returns (uint256) {
        value = _value;
        sender = msg.sender;
        emit ValueSet(_value, msg.sender);
        return _value;
    }

    /**
     * @notice Returns current value
     */
    function getValue() public view returns (uint256) {
        return value;
    }

    /**
     * @notice Returns multiple values
     */
    function getMultiple() public view returns (uint256, address, uint256) {
        return (value, sender, receivedValue);
    }

    /**
     * @notice Function that always reverts with custom error
     */
    function alwaysReverts() public pure {
        revert CustomError("This function always reverts");
    }

    /**
     * @notice Payable function to receive ETH
     */
    function receivePayment() public payable returns (uint256) {
        receivedValue = msg.value;
        emit ValueReceived(msg.value, msg.sender);
        return msg.value;
    }

    /**
     * @notice Function that modifies state (for staticcall testing)
     */
    function modifyState(uint256 _value) public {
        value = _value;
    }

    /**
     * @notice Fallback for empty/low-level calls
     * @dev Empty calldata invokes fallback; without it, call("") would revert.
     *      Teaches that contracts can handle arbitrary calls.
     */
    fallback() external {}
}

/**
 * @title Caller
 * @notice Demonstrates call() - executes in target's context
 */
contract Caller {
    event CallResult(bool success, bytes data);
    event ValueReturned(uint256 value);

    /**
     * @notice Calls setValue on target using low-level call
     * @dev Demonstrates basic call() usage with return data decoding
     */
    function callSetValue(address target, uint256 _value)
        public
        returns (bool success, uint256 returnedValue)
    {
        bytes memory data;
        (success, data) = target.call(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );

        emit CallResult(success, data);

        if (success && data.length > 0) {
            returnedValue = abi.decode(data, (uint256));
            emit ValueReturned(returnedValue);
        }
    }

    /**
     * @notice Calls function with ETH transfer
     * @dev Demonstrates call() with value
     */
    function callWithValue(address target)
        public
        payable
        returns (bool success, uint256 returnedValue)
    {
        bytes memory data;
        (success, data) = target.call{value: msg.value}(
            abi.encodeWithSignature("receivePayment()")
        );

        if (success && data.length > 0) {
            returnedValue = abi.decode(data, (uint256));
        }
    }

    /**
     * @notice Calls function with gas limit
     * @dev Demonstrates call() with explicit gas limit
     */
    function callWithGasLimit(address target, uint256 _value, uint256 gasLimit)
        public
        returns (bool success)
    {
        (success,) = target.call{gas: gasLimit}(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
    }

    /**
     * @notice Calls function and bubbles up error on failure
     * @dev Demonstrates proper error bubbling
     */
    function callAndBubbleError(address target) public {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSignature("alwaysReverts()")
        );

        if (!success) {
            // Bubble up the error message
            if (data.length > 0) {
                assembly {
                    // data layout: [length][data]
                    // We need to skip the first 32 bytes (length) and revert with the rest
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Call failed with no error message");
            }
        }
    }

    /**
     * @notice Uses staticcall to safely read from target
     * @dev Demonstrates staticcall() for read-only operations
     */
    function staticCallGetValue(address target)
        public
        view
        returns (bool success, uint256 returnedValue)
    {
        bytes memory data;
        (success, data) = target.staticcall(
            abi.encodeWithSignature("getValue()")
        );

        if (success && data.length > 0) {
            returnedValue = abi.decode(data, (uint256));
        }
    }

    /**
     * @notice Attempts staticcall on state-modifying function
     * @dev This will fail because staticcall reverts on state changes
     */
    function staticCallModifyState(address target, uint256 _value)
        public
        view
        returns (bool success)
    {
        (success,) = target.staticcall(
            abi.encodeWithSignature("modifyState(uint256)", _value)
        );
        // success will be false because function tries to modify state
    }

    /**
     * @notice Decodes multiple return values
     */
    function callGetMultiple(address target)
        public
        returns (bool success, uint256 val, address addr, uint256 received)
    {
        bytes memory data;
        (success, data) = target.call(
            abi.encodeWithSignature("getMultiple()")
        );

        if (success && data.length > 0) {
            (val, addr, received) = abi.decode(data, (uint256, address, uint256));
        }
    }
}

/**
 * @title DelegateTarget
 * @notice Target contract for delegatecall demonstrations
 * WARNING: Storage layout must match caller!
 */
contract DelegateTarget {
    uint256 public value;  // Slot 0
    address public sender; // Slot 1

    event ValueSetViaDelegateCall(uint256 newValue, address msgSender);

    /**
     * @notice Sets value in the CALLER's storage context
     * @dev When delegatecalled, modifies caller's slot 0 and slot 1
     */
    function setValue(uint256 _value) public returns (uint256) {
        value = _value;
        sender = msg.sender;
        emit ValueSetViaDelegateCall(_value, msg.sender);
        return _value;
    }

    /**
     * @notice Returns current values
     */
    function getValues() public view returns (uint256, address) {
        return (value, sender);
    }
}

/**
 * @title DelegateCaller
 * @notice Demonstrates delegatecall() - executes in caller's context
 * CRITICAL: Storage layout must match DelegateTarget!
 *
 * MISCONCEPTION CALLOUTS (CLAUDE/.cursorrules):
 * • delegatecall does NOT use the callee's storage. It uses OUR (caller's) storage!
 * • delegatecall does NOT copy storage. Target's code writes directly to OUR slots.
 * • Before delegatecall: Our slot 0 = value, slot 1 = sender.
 * • After delegatecall(setValue(42)): Target's "value = _value" writes to OUR slot 0.
 * • The target's storage variables are INTERPRETED as OUR slots by slot position.
 */
contract DelegateCaller {
    uint256 public value;  // Slot 0 - MUST MATCH DelegateTarget
    address public sender; // Slot 1 - MUST MATCH DelegateTarget

    event DelegateCallResult(bool success, bytes data);
    event StorageModified(uint256 newValue, address newSender);

    /**
     * @notice Uses delegatecall to modify OUR storage
     * @dev The target's code runs in our context, modifying our storage!
     */
    function delegateSetValue(address target, uint256 _value)
        public
        returns (bool success, uint256 returnedValue)
    {
        bytes memory data;
        (success, data) = target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );

        emit DelegateCallResult(success, data);

        if (success && data.length > 0) {
            returnedValue = abi.decode(data, (uint256));
            emit StorageModified(value, sender);
        }
    }

    /**
     * @notice Helper to verify our storage was modified
     */
    function getStorageValues() public view returns (uint256, address) {
        return (value, sender);
    }

    /**
     * @notice Demonstrates msg.sender preservation with delegatecall
     * @dev msg.sender remains the original caller, not this contract!
     */
    function delegateAndCheckSender(address target, uint256 _value)
        public
        returns (address storedSender)
    {
        target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        storedSender = sender; // Will be msg.sender, not address(this)!
    }
}

/**
 * @title StorageCorruptionExample
 * @notice Demonstrates the dangers of storage layout mismatch
 * ⚠️ DO NOT USE IN PRODUCTION - FOR EDUCATIONAL PURPOSES ONLY
 */
contract VulnerableProxy {
    address public implementation; // Slot 0
    address public owner;         // Slot 1

    event ImplementationChanged(address newImplementation);
    event OwnerChanged(address newOwner);

    constructor(address _implementation) {
        implementation = _implementation;
        owner = msg.sender;
    }

    /**
     * @notice Delegates call to implementation contract
     * @dev ⚠️ VULNERABLE: If implementation has wrong storage layout,
     *      it can corrupt our storage!
     */
    function delegateToImplementation(bytes memory data)
        public
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = implementation.delegatecall(data);

        // Log if storage was changed (for demonstration)
        emit ImplementationChanged(implementation);
        emit OwnerChanged(owner);
    }

    /**
     * @notice Returns current storage slots
     */
    function getStorageSlots() public view returns (address, address) {
        return (implementation, owner);
    }
}

/**
 * @title MaliciousImplementation
 * @notice Malicious contract with misaligned storage
 * ⚠️ FOR EDUCATIONAL PURPOSES ONLY - Shows storage corruption attack
 *
 * STEP-BY-STEP STORAGE CORRUPTION (memory/storage before & after):
 * -----------------------------------------------------------------
 * Proxy layout:  implementation (slot 0), owner (slot 1)
 * Malicious:     owner (slot 0)  <- MISALIGNED!
 *
 * When proxy calls delegatecall(malicious.takeOver()):
 * 1. BEFORE: Proxy slot 0 = implementation addr, slot 1 = owner
 * 2. Malicious code runs IN PROXY'S CONTEXT (does NOT use malicious's storage)
 * 3. Malicious's "owner" maps to slot 0 in proxy's storage (first state var)
 * 4. owner = msg.sender writes msg.sender to PROXY'S slot 0
 * 5. AFTER: Proxy slot 0 = msg.sender (attacker!), slot 1 = owner (unchanged)
 * 6. Proxy's implementation pointer is now corrupted—attacker controls the proxy!
 *
 * MISCONCEPTION: delegatecall does NOT use callee storage. It uses caller storage.
 */
contract MaliciousImplementation {
    address public owner; // Slot 0 - MISALIGNED! This is proxy's implementation slot!

    /**
     * @notice Takes over the proxy by corrupting slot 0
     * @dev When delegatecalled, this overwrites proxy's implementation address!
     *      The write goes to CALLER's (proxy's) slot 0, not this contract's storage.
     */
    function takeOver() public {
        owner = msg.sender; // Overwrites proxy's implementation in slot 0!
    }

    /**
     * @notice Demonstrates reading proxy's storage
     */
    function readProxyStorage() public view returns (address) {
        return owner; // Actually reads proxy's implementation address!
    }
}

/**
 * @title SafeProxy
 * @notice Properly aligned proxy contract
 * ✅ SAFE: Storage layout matches implementation
 */
contract SafeProxy {
    address public implementation; // Slot 0
    address public owner;         // Slot 1

    event Executed(bool success, bytes returnData);

    constructor(address _implementation, address _owner) {
        implementation = _implementation;
        owner = _owner;
    }

    /**
     * @notice Safely delegates to implementation
     * @dev Safe because SafeImplementation has matching storage layout
     */
    function execute(bytes memory data)
        public
        returns (bool success, bytes memory returnData)
    {
        require(msg.sender == owner, "Not owner");
        (success, returnData) = implementation.delegatecall(data);
        emit Executed(success, returnData);
    }

    /**
     * @notice Upgrade implementation (owner only)
     */
    function upgrade(address newImplementation) public {
        require(msg.sender == owner, "Not owner");
        implementation = newImplementation;
    }
}

/**
 * @title SafeImplementation
 * @notice Properly aligned implementation
 * ✅ SAFE: Storage layout matches SafeProxy
 */
contract SafeImplementation {
    address public implementation; // Slot 0 - MATCHES SafeProxy
    address public owner;         // Slot 1 - MATCHES SafeProxy
    uint256 public value;         // Slot 2 - Additional storage OK

    event ValueSet(uint256 newValue);

    /**
     * @notice Safely modifies proxy storage
     * @dev Safe because storage alignment is correct
     */
    function setValue(uint256 _value) public returns (uint256) {
        value = _value;
        emit ValueSet(_value);
        return _value;
    }

    /**
     * @notice Returns all values
     */
    function getValues() public view returns (address, address, uint256) {
        return (implementation, owner, value);
    }

    /**
     * @notice Demonstrates that additional storage slots are safe
     */
    function incrementValue() public returns (uint256) {
        value += 1;
        return value;
    }
}

/**
 * @title StaticCallExample
 * @notice Demonstrates staticcall() - read-only enforcement
 */
contract StaticCallExample {
    uint256 public value;

    event StaticCallAttempted(bool success);
    event ReadValue(uint256 val);

    /**
     * @notice Safely reads from external contract using staticcall
     * @dev staticcall guarantees no state changes
     */
    function safeRead(address target)
        public
        returns (bool success, uint256 returnedValue)
    {
        bytes memory data;
        (success, data) = target.staticcall(
            abi.encodeWithSignature("getValue()")
        );

        emit StaticCallAttempted(success);

        if (success && data.length > 0) {
            returnedValue = abi.decode(data, (uint256));
            emit ReadValue(returnedValue);
        }
    }

    /**
     * @notice Attempts to modify state via staticcall (will fail)
     * @dev This demonstrates that staticcall prevents state modifications
     */
    function attemptWrite(address target, uint256 _value)
        public
        returns (bool success)
    {
        (success,) = target.staticcall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );

        emit StaticCallAttempted(success);
        // success will be false because setValue modifies state
    }
}

/**
 * @title ReturnDataExample
 * @notice Demonstrates proper return data handling
 */
contract ReturnDataExample {
    event DecodedSingle(uint256 value);
    event DecodedMultiple(uint256 val1, address val2, uint256 val3);
    event ErrorBubbled(string message);

    /**
     * @notice Calls external function and decodes return data
     */
    function callAndDecode(address target)
        public
        returns (bool success, uint256 decodedValue)
    {
        bytes memory data;
        (success, data) = target.call(
            abi.encodeWithSignature("getValue()")
        );

        if (success && data.length > 0) {
            decodedValue = abi.decode(data, (uint256));
            emit DecodedSingle(decodedValue);
        }
    }

    /**
     * @notice Handles functions that return multiple values
     */
    function handleMultipleReturns(address target)
        public
        returns (bool success, uint256 val1, address val2, uint256 val3)
    {
        bytes memory data;
        (success, data) = target.call(
            abi.encodeWithSignature("getMultiple()")
        );

        if (success && data.length > 0) {
            (val1, val2, val3) = abi.decode(data, (uint256, address, uint256));
            emit DecodedMultiple(val1, val2, val3);
        }
    }

    /**
     * @notice Properly bubbles up error messages from failed calls
     */
    function bubbleError(address target) public {
        (bool success, bytes memory data) = target.call(
            abi.encodeWithSignature("alwaysReverts()")
        );

        if (!success) {
            if (data.length > 0) {
                // Extract and bubble up the error
                assembly {
                    let returnDataSize := mload(data)
                    revert(add(data, 32), returnDataSize)
                }
            } else {
                revert("Call failed without error message");
            }
        }
    }

    /**
     * @notice Demonstrates handling of empty return data
     */
    function handleEmptyReturn(address target)
        public
        returns (bool success, bool hasData)
    {
        bytes memory data;
        (success, data) = target.call(
            abi.encodeWithSignature("someFunction()")
        );

        hasData = data.length > 0;
    }
}

/**
 * @title GasForwardingExample
 * @notice Demonstrates gas forwarding behavior
 */
contract GasForwardingExample {
    event GasUsed(uint256 gasUsed);

    /**
     * @notice Forwards all available gas (default behavior)
     */
    function forwardAllGas(address target, uint256 _value)
        public
        returns (bool success)
    {
        uint256 gasBefore = gasleft();
        (success,) = target.call(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        uint256 gasUsed = gasBefore - gasleft();
        emit GasUsed(gasUsed);
    }

    /**
     * @notice Forwards limited gas
     */
    function forwardLimitedGas(address target, uint256 _value, uint256 gasLimit)
        public
        returns (bool success)
    {
        (success,) = target.call{gas: gasLimit}(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
    }

    /**
     * @notice Demonstrates EIP-150 (63/64 rule)
     * @dev Only 63/64 of gas is forwarded automatically
     */
    function demonstrateGasRule(address target, uint256 _value)
        public
        returns (uint256 gasBeforeCall, uint256 gasAfterCall)
    {
        gasBeforeCall = gasleft();
        target.call(abi.encodeWithSignature("setValue(uint256)", _value));
        gasAfterCall = gasleft();
        // Difference shows the 1/64 kept by caller
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                          KEY TAKEAWAYS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. THREE TYPES OF LOW-LEVEL CALLS
 *    ✅ call(): Executes in target's context (storage, balance, address)
 *    ✅ delegatecall(): Executes in caller's context (proxy pattern)
 *    ✅ staticcall(): Read-only call (reverts on state changes)
 *    ✅ Each has different use cases and risks!
 *
 * 2. DELEGATECALL IS POWERFUL BUT DANGEROUS
 *    ✅ Executes code in YOUR contract's context
 *    ✅ Storage changes happen in YOUR contract
 *    ✅ Used in proxy patterns (Project 10)
 *    ⚠️  Storage layout must match exactly (corruption risk!)
 *
 * 3. ALWAYS CHECK RETURN VALUES
 *    ✅ Low-level calls return (bool success, bytes data)
 *    ✅ Check success before using data
 *    ✅ Handle empty return data
 *    ✅ Bubble up errors properly
 *
 * 4. GAS FORWARDING BEHAVIOR
 *    ✅ call() forwards all remaining gas (by default)
 *    ✅ EIP-150: Caller keeps 1/64 of gas
 *    ✅ Can limit gas with {gas: amount}
 *    ✅ Malicious contracts can consume all gas!
 *
 * 5. STATICCALL PREVENTS STATE CHANGES
 *    ✅ Reverts if target tries to modify state
 *    ✅ Perfect for view functions
 *    ✅ Safer than regular call for read-only operations
 *    ✅ Use when you don't want state changes
 *
 * 6. RETURN DATA HANDLING IS CRITICAL
 *    ✅ Decode return data with abi.decode()
 *    ✅ Handle empty return data
 *    ✅ Bubble up errors from failed calls
 *    ✅ Validate decoded data before use
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        COMMON MISTAKES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ❌ Not checking return values (silent failures!)
 * ❌ Using delegatecall with mismatched storage layout (corruption!)
 * ❌ Not handling empty return data
 * ❌ Forwarding all gas to untrusted contracts (DoS risk)
 * ❌ Not bubbling up errors properly
 * ❌ Using call() for view functions (should use staticcall)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          NEXT STEPS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * • Study proxy patterns (Project 10) - uses delegatecall
 * • Learn about library contracts
 * • Explore multicall patterns
 * • Move to Project 16 to learn about contract factories
 */
