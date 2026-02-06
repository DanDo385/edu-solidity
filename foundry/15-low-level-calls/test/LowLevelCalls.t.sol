// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/LowLevelCallsSolution.sol";

contract LowLevelCallsTest is Test {
    TargetContract public target;
    Caller public caller;
    DelegateTarget public delegateTarget;
    DelegateCaller public delegateCaller;
    VulnerableProxy public vulnerableProxy;
    MaliciousImplementation public maliciousImpl;
    SafeProxy public safeProxy;
    SafeImplementation public safeImpl;
    StaticCallExample public staticCallExample;
    ReturnDataExample public returnDataExample;
    GasForwardingExample public gasForwardingExample;

    address public user1;
    address public user2;

    function setUp() public {
        target = new TargetContract();
        caller = new Caller();
        delegateTarget = new DelegateTarget();
        delegateCaller = new DelegateCaller();
        maliciousImpl = new MaliciousImplementation();
        vulnerableProxy = new VulnerableProxy(address(maliciousImpl));

        safeImpl = new SafeImplementation();
        safeProxy = new SafeProxy(address(safeImpl), address(this));

        staticCallExample = new StaticCallExample();
        returnDataExample = new ReturnDataExample();
        gasForwardingExample = new GasForwardingExample();

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    // ========================================
    // CALL TESTS
    // ========================================
    // INVARIANT: call() runs in target context; target storage modified. Failure = wrong call semantics.

    function test_Call_BasicSuccess() public {
        (bool success, uint256 returned) = caller.callSetValue(address(target), 42);

        assertTrue(success, "Call should succeed");
        assertEq(returned, 42, "Should return correct value");
        assertEq(target.value(), 42, "Target value should be updated");
        assertEq(target.sender(), address(caller), "Sender should be caller contract");
    }

    function test_Call_WithValue() public {
        vm.deal(address(caller), 1 ether);

        vm.prank(user1);
        (bool success, uint256 returned) = caller.callWithValue{value: 1 ether}(address(target));

        assertTrue(success, "Call with value should succeed");
        assertEq(returned, 1 ether, "Should return sent amount");
        assertEq(target.receivedValue(), 1 ether, "Target should record received value");
        assertEq(address(target).balance, 1 ether, "Target should have received ETH");
    }

    function test_Call_WithGasLimit_Success() public {
        bool success = caller.callWithGasLimit(address(target), 100, 100000);
        assertTrue(success, "Call with sufficient gas should succeed");
        assertEq(target.value(), 100, "Value should be set");
    }

    function test_Call_WithGasLimit_Failure() public {
        // Very low gas limit should cause failure
        bool success = caller.callWithGasLimit(address(target), 100, 1000);
        assertFalse(success, "Call with insufficient gas should fail");
    }

    function test_Call_ErrorBubbling() public {
        vm.expectRevert(); // Should bubble up the CustomError
        caller.callAndBubbleError(address(target));
    }

    function test_Call_MultipleReturns() public {
        // First set some values
        target.setValue(999);
        vm.deal(address(target), 5 ether);
        target.receivePayment{value: 1 ether}();

        (bool success, uint256 val, address addr, uint256 received) =
            caller.callGetMultiple(address(target));

        assertTrue(success, "Call should succeed");
        assertEq(val, 999, "Should return correct value");
        assertEq(received, 1 ether, "Should return correct received amount");
    }

    // ========================================
    // STATICCALL TESTS
    // ========================================

    function test_StaticCall_ReadSuccess() public {
        target.setValue(123);

        (bool success, uint256 returned) = caller.staticCallGetValue(address(target));

        assertTrue(success, "Static call should succeed");
        assertEq(returned, 123, "Should return correct value");
    }

    function test_StaticCall_PreventWrite() public view {
        // Attempting to modify state via staticcall should fail
        bool success = caller.staticCallModifyState(address(target), 456);

        assertFalse(success, "Static call should fail on state modification");
    }

    function test_StaticCallExample_SafeRead() public {
        target.setValue(789);

        (bool success, uint256 returned) = staticCallExample.safeRead(address(target));

        assertTrue(success, "Safe read should succeed");
        assertEq(returned, 789, "Should return correct value");
    }

    function test_StaticCallExample_AttemptWrite() public {
        bool success = staticCallExample.attemptWrite(address(target), 999);

        assertFalse(success, "Write attempt via staticcall should fail");
    }

    // ========================================
    // DELEGATECALL TESTS
    // ========================================
    // INVARIANT: delegatecall() runs in caller context; caller storage modified. Failure = EVM misunderstanding.

    function test_DelegateCall_ModifiesCallerStorage() public {
        console.log("Before delegatecall:");
        console.log("DelegateCaller value:", delegateCaller.value());
        console.log("DelegateCaller sender:", delegateCaller.sender());

        vm.prank(user1);
        (bool success, uint256 returned) = delegateCaller.delegateSetValue(
            address(delegateTarget),
            555
        );

        assertTrue(success, "Delegatecall should succeed");
        assertEq(returned, 555, "Should return correct value");

        console.log("\nAfter delegatecall:");
        console.log("DelegateCaller value:", delegateCaller.value());
        console.log("DelegateCaller sender:", delegateCaller.sender());

        // CRITICAL: DelegateCaller's storage is modified, not DelegateTarget's!
        assertEq(delegateCaller.value(), 555, "Caller's value should be modified");
        assertEq(delegateCaller.sender(), user1, "Caller's sender should be msg.sender");

        // DelegateTarget's storage should be unchanged
        assertEq(delegateTarget.value(), 0, "Target's value should be unchanged");
        assertEq(delegateTarget.sender(), address(0), "Target's sender should be unchanged");
    }

    function test_DelegateCall_PreservesMsgSender() public {
        vm.prank(user1);
        address storedSender = delegateCaller.delegateAndCheckSender(
            address(delegateTarget),
            777
        );

        // msg.sender is preserved in delegatecall
        assertEq(storedSender, user1, "msg.sender should be preserved");
        assertNotEq(storedSender, address(delegateCaller), "Should NOT be caller contract");
    }

    function test_DelegateCall_ContextVisualization() public {
        console.log("\n=== DELEGATECALL CONTEXT DEMONSTRATION ===");
        console.log("\nSetup:");
        console.log("- DelegateCaller deployed at:", address(delegateCaller));
        console.log("- DelegateTarget deployed at:", address(delegateTarget));
        console.log("- User1 address:", user1);

        console.log("\nInitial state:");
        (uint256 callerVal, address callerSender) = delegateCaller.getStorageValues();
        (uint256 targetVal, address targetSender) = delegateTarget.getValues();
        console.log("DelegateCaller: value=%d, sender=%s", callerVal, callerSender);
        console.log("DelegateTarget: value=%d, sender=%s", targetVal, targetSender);

        console.log("\nExecuting: user1 -> DelegateCaller.delegateSetValue(DelegateTarget, 999)");
        vm.prank(user1);
        delegateCaller.delegateSetValue(address(delegateTarget), 999);

        console.log("\nFinal state:");
        (callerVal, callerSender) = delegateCaller.getStorageValues();
        (targetVal, targetSender) = delegateTarget.getValues();
        console.log("DelegateCaller: value=%d, sender=%s", callerVal, callerSender);
        console.log("DelegateTarget: value=%d, sender=%s", targetVal, targetSender);

        console.log("\nKey observations:");
        console.log("1. DelegateCaller's storage was modified (value=999)");
        console.log("2. DelegateTarget's storage is unchanged (value=0)");
        console.log("3. msg.sender was preserved as user1, not DelegateCaller");
        console.log("4. Code from DelegateTarget executed in DelegateCaller's context");
    }

    // ========================================
    // STORAGE CORRUPTION TESTS
    // ========================================

    function test_StorageCorruption_VulnerableProxy() public {
        console.log("\n=== STORAGE CORRUPTION ATTACK ===");

        console.log("\nInitial proxy state:");
        (address impl, address owner) = vulnerableProxy.getStorageSlots();
        console.log("Slot 0 (implementation):", impl);
        console.log("Slot 1 (owner):", owner);

        assertEq(impl, address(maliciousImpl), "Implementation should be maliciousImpl");
        assertEq(owner, address(this), "Owner should be test contract");

        console.log("\nExecuting attack: delegatecall to MaliciousImplementation.takeOver()");
        vm.prank(user1);
        vulnerableProxy.delegateToImplementation(
            abi.encodeWithSignature("takeOver()")
        );

        console.log("\nProxy state after attack:");
        (impl, owner) = vulnerableProxy.getStorageSlots();
        console.log("Slot 0 (implementation):", impl);
        console.log("Slot 1 (owner):", owner);

        // CRITICAL: Slot 0 (implementation) has been overwritten!
        assertEq(impl, user1, "Implementation corrupted to attacker address!");
        assertEq(owner, address(this), "Owner remains unchanged (slot 1)");

        console.log("\n[!] ATTACK SUCCESSFUL!");
        console.log("The proxy's implementation address has been corrupted.");
        console.log("Attacker (user1) is now in slot 0 instead of implementation contract.");
        console.log("\nWhy? MaliciousImplementation has 'address owner' in slot 0,");
        console.log("but VulnerableProxy expects 'address implementation' in slot 0.");
        console.log("Storage misalignment caused corruption!");
    }

    function test_StorageCorruption_Visualization() public {
        console.log("\n=== STORAGE LAYOUT COMPARISON ===");
        console.log("\nVulnerableProxy storage:");
        console.log("Slot 0: address implementation");
        console.log("Slot 1: address owner");

        console.log("\nMaliciousImplementation storage:");
        console.log("Slot 0: address owner  [!] MISALIGNED!");

        console.log("\nWhat happens during delegatecall:");
        console.log("1. Proxy delegates to MaliciousImpl.takeOver()");
        console.log("2. takeOver() sets 'owner = msg.sender'");
        console.log("3. 'owner' is in slot 0 in MaliciousImpl");
        console.log("4. But slot 0 in Proxy is 'implementation'!");
        console.log("5. Result: Proxy's implementation gets overwritten");

        console.log("\nLesson: Storage layouts MUST match in proxy patterns!");
    }

    /// INVARIANT: Aligned storage layouts allow safe delegatecall. Failure = storage corruption.
    function test_SafeProxy_CorrectAlignment() public {
        console.log("\n=== SAFE PROXY DEMONSTRATION ===");

        // Read proxy storage (implementation, owner) before execution
        address impl = safeProxy.implementation();
        address ownerAddr = safeProxy.owner();
        console.log("\nBefore execution:");
        console.log("SafeProxy implementation:", impl);
        console.log("SafeProxy owner:", ownerAddr);

        // Execute setValue through proxy (delegatecalls to implementation)
        safeProxy.execute(abi.encodeWithSignature("setValue(uint256)", 888));

        // Call getValues through proxy via execute (delegatecall to implementation)
        (bool success, bytes memory returnData) =
            safeProxy.execute(abi.encodeWithSignature("getValues()"));
        require(success, "Call failed");

        (address newImpl, address newOwner, uint256 value) =
            abi.decode(returnData, (address, address, uint256));

        console.log("\nAfter execution:");
        console.log("Implementation:", newImpl);
        console.log("Owner:", newOwner);
        console.log("Value:", value);

        assertEq(value, 888, "Value should be set correctly");
        console.log("\n[OK] Safe because storage layouts match!");
    }

    // ========================================
    // RETURN DATA TESTS
    // ========================================

    function test_ReturnData_SingleValue() public {
        target.setValue(12345);

        (bool success, uint256 decoded) = returnDataExample.callAndDecode(address(target));

        assertTrue(success, "Call should succeed");
        assertEq(decoded, 12345, "Should decode correct value");
    }

    function test_ReturnData_MultipleValues() public {
        target.setValue(111);
        vm.deal(address(target), 5 ether);
        target.receivePayment{value: 2 ether}();

        (bool success, uint256 val1, address val2, uint256 val3) =
            returnDataExample.handleMultipleReturns(address(target));

        assertTrue(success, "Call should succeed");
        assertEq(val1, 111, "First value should be correct");
        assertEq(val3, 2 ether, "Third value should be correct");
    }

    function test_ReturnData_ErrorBubbling() public {
        vm.expectRevert(); // Should bubble up CustomError
        returnDataExample.bubbleError(address(target));
    }

    // ========================================
    // GAS FORWARDING TESTS
    // ========================================

    function test_GasForwarding_AllGas() public {
        bool success = gasForwardingExample.forwardAllGas(address(target), 123);
        assertTrue(success, "Should forward all gas successfully");
        assertEq(target.value(), 123, "Target should be updated");
    }

    function test_GasForwarding_LimitedGas_Success() public {
        bool success = gasForwardingExample.forwardLimitedGas(
            address(target),
            456,
            100000
        );
        assertTrue(success, "Should succeed with sufficient gas");
        assertEq(target.value(), 456, "Target should be updated");
    }

    function test_GasForwarding_LimitedGas_Failure() public {
        bool success = gasForwardingExample.forwardLimitedGas(
            address(target),
            789,
            1000 // Too low
        );
        assertFalse(success, "Should fail with insufficient gas");
    }

    function test_GasForwarding_63_64_Rule() public {
        (uint256 before, uint256 afterCall) = gasForwardingExample.demonstrateGasRule(
            address(target),
            321
        );

        console.log("\n=== EIP-150 GAS FORWARDING (63/64 RULE) ===");
        console.log("Gas before call:", before);
        console.log("Gas after call:", afterCall);
        console.log("Gas used:", before - afterCall);
        console.log("\nNote: Only 63/64 of available gas is automatically forwarded");
        console.log("The remaining 1/64 is kept for post-call execution");

        assertTrue(before > afterCall, "Gas should be consumed");
        assertEq(target.value(), 321, "Call should succeed");
    }

    // ========================================
    // COMPARISON TESTS
    // ========================================

    function test_Comparison_CallVsDelegateCall() public {
        console.log("\n=== CALL vs DELEGATECALL COMPARISON ===");

        TargetContract target1 = new TargetContract();
        TargetContract target2 = new TargetContract();

        console.log("\n1. Using CALL:");
        console.log("   Caller calls Target.setValue(100)");
        caller.callSetValue(address(target1), 100);
        console.log("   - Target's storage modified: value =", target1.value());
        console.log("   - Target's sender recorded:", target1.sender());
        console.log("   - Caller's storage unchanged");

        console.log("\n2. Using DELEGATECALL:");
        console.log("   DelegateCaller delegatecalls DelegateTarget.setValue(200)");
        vm.prank(user1);
        delegateCaller.delegateSetValue(address(delegateTarget), 200);
        console.log("   - DelegateCaller's storage modified: value =", delegateCaller.value());
        console.log("   - DelegateCaller's sender recorded:", delegateCaller.sender());
        console.log("   - DelegateTarget's storage unchanged: value =", delegateTarget.value());

        console.log("\nKey Difference:");
        console.log("- CALL: Executes in TARGET's context, modifies TARGET's storage");
        console.log("- DELEGATECALL: Executes in CALLER's context, modifies CALLER's storage");
    }

    function test_Comparison_AllThreeTypes() public {
        console.log("\n=== ALL THREE CALL TYPES ===");

        target.setValue(500);

        console.log("\n1. CALL - External execution:");
        (bool success1, uint256 val1) = caller.callSetValue(address(target), 100);
        console.log("   Success:", success1);
        console.log("   Target value:", target.value());
        console.log("   Context: Target contract");

        console.log("\n2. DELEGATECALL - Code borrowing:");
        vm.prank(user1);
        (bool success2, uint256 val2) = delegateCaller.delegateSetValue(
            address(delegateTarget),
            200
        );
        console.log("   Success:", success2);
        console.log("   DelegateCaller value:", delegateCaller.value());
        console.log("   Context: Caller contract");

        console.log("\n3. STATICCALL - Read-only:");
        (bool success3, uint256 val3) = caller.staticCallGetValue(address(target));
        console.log("   Success:", success3);
        console.log("   Read value:", val3);
        console.log("   Context: Target contract (read-only)");

        console.log("\nAttempting state change via STATICCALL:");
        bool success4 = caller.staticCallModifyState(address(target), 999);
        console.log("   Success:", success4, "(false = prevented state change)");
    }

    // ========================================
    // EDGE CASE TESTS
    // ========================================

    function test_EdgeCase_CallToEOA() public {
        // Calling an EOA (Externally Owned Account) should succeed but do nothing
        (bool success,) = address(user1).call(
            abi.encodeWithSignature("nonExistentFunction()")
        );

        assertTrue(success, "Call to EOA should succeed");
    }

    /// INVARIANT: Empty calldata invokes fallback; must succeed if contract has fallback.
    function test_EdgeCase_EmptyCallData() public {
        (bool success,) = address(target).call("");
        assertTrue(success, "Empty call should succeed");
    }

    function test_EdgeCase_DelegateCallToEOA() public {
        // Delegatecall to EOA succeeds but does nothing
        (bool success,) = address(user1).delegatecall(
            abi.encodeWithSignature("nonExistentFunction()")
        );

        assertTrue(success, "Delegatecall to EOA should succeed");
    }

    function test_EdgeCase_ZeroValueCall() public {
        (bool success,) = caller.callWithValue{value: 0}(address(target));
        assertTrue(success, "Zero value call should succeed");
    }

    // ========================================
    // SECURITY TESTS
    // ========================================

    /// INVARIANT: Call to non-existent function must fail when contract has no fallback.
    /// Uses Caller (no fallback) not TargetContract (has fallback for empty-call tests).
    function test_Security_CheckReturnValue() public {
        (bool success,) = address(caller).call(
            abi.encodeWithSignature("nonExistentFunction()")
        );
        assertFalse(success, "Should fail when calling non-existent function");
    }

    function test_Security_StaticCallPreventsReentrancy() public view {
        // staticcall can prevent certain reentrancy attacks
        // because it prevents state modifications
        (bool success,) = address(target).staticcall(
            abi.encodeWithSignature("getValue()")
        );

        assertTrue(success, "Static call to view function should succeed");
    }

    function testFuzz_CallWithRandomValue(uint256 randomValue) public {
        vm.assume(randomValue < type(uint128).max); // Reasonable bounds

        (bool success, uint256 returned) = caller.callSetValue(
            address(target),
            randomValue
        );

        assertTrue(success, "Call should succeed");
        assertEq(returned, randomValue, "Should return set value");
        assertEq(target.value(), randomValue, "Target should have correct value");
    }

    function testFuzz_DelegateCallWithRandomValue(uint256 randomValue) public {
        vm.assume(randomValue < type(uint128).max);

        (bool success, uint256 returned) = delegateCaller.delegateSetValue(
            address(delegateTarget),
            randomValue
        );

        assertTrue(success, "Delegatecall should succeed");
        assertEq(delegateCaller.value(), randomValue, "Caller value should be set");
        assertEq(delegateTarget.value(), 0, "Target value should remain 0");
    }
}
