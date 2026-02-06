// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/LowLevelCallsSolution.sol";

contract DeployLowLevelCalls is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Deploying Low-Level Calls Demonstration Contracts ===\n");

        // Deploy basic call demonstration contracts
        console.log("1. Deploying basic call demonstration contracts...");
        TargetContract target = new TargetContract();
        Caller caller = new Caller();
        console.log("   TargetContract:", address(target));
        console.log("   Caller:", address(caller));

        // Deploy delegatecall demonstration contracts
        console.log("\n2. Deploying delegatecall demonstration contracts...");
        DelegateTarget delegateTarget = new DelegateTarget();
        DelegateCaller delegateCaller = new DelegateCaller();
        console.log("   DelegateTarget:", address(delegateTarget));
        console.log("   DelegateCaller:", address(delegateCaller));

        // Deploy storage corruption example contracts
        console.log("\n3. Deploying storage corruption examples...");
        MaliciousImplementation maliciousImpl = new MaliciousImplementation();
        VulnerableProxy vulnerableProxy = new VulnerableProxy(address(maliciousImpl));
        console.log("   MaliciousImplementation:", address(maliciousImpl));
        console.log("   VulnerableProxy:", address(vulnerableProxy));
        console.log("   [!] WARNING: VulnerableProxy is intentionally vulnerable!");

        // Deploy safe proxy contracts
        console.log("\n4. Deploying safe proxy pattern...");
        SafeImplementation safeImpl = new SafeImplementation();
        SafeProxy safeProxy = new SafeProxy(address(safeImpl), msg.sender);
        console.log("   SafeImplementation:", address(safeImpl));
        console.log("   SafeProxy:", address(safeProxy));
        console.log("   [OK] Safe proxy with correct storage alignment");

        // Deploy utility contracts
        console.log("\n5. Deploying utility contracts...");
        StaticCallExample staticCallExample = new StaticCallExample();
        ReturnDataExample returnDataExample = new ReturnDataExample();
        GasForwardingExample gasForwardingExample = new GasForwardingExample();
        console.log("   StaticCallExample:", address(staticCallExample));
        console.log("   ReturnDataExample:", address(returnDataExample));
        console.log("   GasForwardingExample:", address(gasForwardingExample));

        // Demonstrate basic call
        console.log("\n=== Demonstration: Basic Call ===");
        (bool success, uint256 returnedValue) = caller.callSetValue(address(target), 42);
        console.log("Call success:", success);
        console.log("Returned value:", returnedValue);
        console.log("Target value:", target.value());

        // Demonstrate delegatecall
        console.log("\n=== Demonstration: DelegateCall ===");
        console.log("Before delegatecall:");
        console.log("  DelegateCaller value:", delegateCaller.value());

        (bool delSuccess,) = delegateCaller.delegateSetValue(address(delegateTarget), 100);
        console.log("DelegateCall success:", delSuccess);
        console.log("After delegatecall:");
        console.log("  DelegateCaller value:", delegateCaller.value());
        console.log("  DelegateTarget value:", delegateTarget.value());
        console.log("  Notice: DelegateCaller's storage was modified, not DelegateTarget's!");

        // Demonstrate staticcall
        console.log("\n=== Demonstration: StaticCall ===");
        (bool staticSuccess, uint256 staticValue) = caller.staticCallGetValue(address(target));
        console.log("StaticCall success:", staticSuccess);
        console.log("Read value:", staticValue);
        console.log("Notice: StaticCall can only read, not write");

        // Demonstrate storage corruption
        console.log("\n=== Demonstration: Storage Corruption Attack ===");
        console.log("VulnerableProxy before attack:");
        (address implBefore, address ownerBefore) = vulnerableProxy.getStorageSlots();
        console.log("  Implementation (slot 0):", implBefore);
        console.log("  Owner (slot 1):", ownerBefore);

        vulnerableProxy.delegateToImplementation(
            abi.encodeWithSignature("takeOver()")
        );

        console.log("VulnerableProxy after attack:");
        (address implAfter, address ownerAfter) = vulnerableProxy.getStorageSlots();
        console.log("  Implementation (slot 0):", implAfter);
        console.log("  Owner (slot 1):", ownerAfter);
        console.log("  [!] CORRUPTED! Implementation slot now contains:", implAfter);

        console.log("\n=== Deployment Summary ===");
        console.log("\nKey Contracts:");
        console.log("- TargetContract:", address(target));
        console.log("- Caller:", address(caller));
        console.log("- DelegateCaller:", address(delegateCaller));
        console.log("- SafeProxy:", address(safeProxy));
        console.log("- VulnerableProxy:", address(vulnerableProxy), "(VULNERABLE!)");

        console.log("\n[!] SECURITY WARNINGS:");
        console.log("1. VulnerableProxy is INTENTIONALLY vulnerable for education");
        console.log("2. MaliciousImplementation demonstrates storage corruption");
        console.log("3. NEVER use delegatecall without matching storage layouts");
        console.log("4. ALWAYS check return values from low-level calls");
        console.log("5. Use staticcall for untrusted read-only operations");

        console.log("\nNext Steps:");
        console.log("1. Run tests: forge test -vvv");
        console.log("2. Study storage corruption example carefully");
        console.log("3. Review safe proxy pattern implementation");
        console.log("4. Understand when to use each call type");

        vm.stopBroadcast();
    }

    /**
     * @notice Helper function to demonstrate call types in a single transaction
     */
    function demonstrateCallTypes() public {
        console.log("\n=== CALL TYPE COMPARISON ===\n");

        TargetContract target = new TargetContract();
        Caller caller = new Caller();
        DelegateTarget delegateTarget = new DelegateTarget();
        DelegateCaller delegateCaller = new DelegateCaller();

        console.log("1. CALL - Executes in target's context");
        caller.callSetValue(address(target), 100);
        console.log("   Target value:", target.value());
        console.log("   Target sender:", target.sender());

        console.log("\n2. DELEGATECALL - Executes in caller's context");
        delegateCaller.delegateSetValue(address(delegateTarget), 200);
        console.log("   DelegateCaller value:", delegateCaller.value());
        console.log("   DelegateTarget value:", delegateTarget.value(), "(unchanged!)");

        console.log("\n3. STATICCALL - Read-only execution");
        target.setValue(300);
        (bool success, uint256 value) = caller.staticCallGetValue(address(target));
        console.log("   Success:", success);
        console.log("   Read value:", value);

        console.log("\n4. STATICCALL preventing writes");
        bool writeSuccess = caller.staticCallModifyState(address(target), 999);
        console.log("   Write attempt success:", writeSuccess, "(should be false)");
    }
}

/**
 * @title InteractiveDemo
 * @notice Script for interactive demonstration of low-level calls
 */
contract InteractiveDemo is Script {
    function runCallDemo() public {
        console.log("=== Interactive Call Demo ===");
        // Users can extend this for interactive testing
    }

    function runDelegateCallDemo() public {
        console.log("=== Interactive DelegateCall Demo ===");
        // Users can extend this for interactive testing
    }

    function runStorageCorruptionDemo() public {
        console.log("=== Interactive Storage Corruption Demo ===");

        MaliciousImplementation malicious = new MaliciousImplementation();
        VulnerableProxy proxy = new VulnerableProxy(address(malicious));

        console.log("\nBefore attack:");
        (address impl, address owner) = proxy.getStorageSlots();
        console.log("Implementation:", impl);
        console.log("Owner:", owner);

        console.log("\nExecuting attack...");
        proxy.delegateToImplementation(abi.encodeWithSignature("takeOver()"));

        console.log("\nAfter attack:");
        (impl, owner) = proxy.getStorageSlots();
        console.log("Implementation:", impl, "(CORRUPTED!)");
        console.log("Owner:", owner);

        console.log("\nExplanation:");
        console.log("- MaliciousImplementation has 'address owner' in slot 0");
        console.log("- VulnerableProxy has 'address implementation' in slot 0");
        console.log("- When delegatecalled, malicious code writes to slot 0");
        console.log("- This overwrites proxy's implementation address!");
        console.log("- Result: Complete storage corruption");
    }
}
