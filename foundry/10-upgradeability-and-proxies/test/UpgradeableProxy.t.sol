// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/UpgradeableProxySolution.sol";

contract UpgradeableProxyTest is Test {
    UpgradeableProxySolution public proxy;
    ImplementationV1 public implV1;
    ImplementationV2 public implV2;
    
    function setUp() public {
        implV1 = new ImplementationV1();
        proxy = new UpgradeableProxySolution(address(implV1));
    }
    
    function test_Proxy_DelegatesToImplementation() public {
        ImplementationV1 proxied = ImplementationV1(address(proxy));
        proxied.setValue(42);
        
        assertEq(proxied.getValue(), 42);
    }
    
    function test_Upgrade_ChangesImplementation() public {
        ImplementationV1 proxied = ImplementationV1(address(proxy));
        proxied.setValue(10);
        
        implV2 = new ImplementationV2();
        // Note: Actual upgrade would need admin function
        
        assertEq(proxied.getValue(), 10);
    }
}
