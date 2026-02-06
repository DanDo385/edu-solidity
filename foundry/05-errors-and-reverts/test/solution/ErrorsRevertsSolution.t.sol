// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/solution/ErrorsRevertsSolution.sol";

/**
 * @title ErrorsRevertsSolutionTest
 * @notice Comprehensive test suite for ErrorsReverts contract
 * @dev Reference implementation showing best practices for testing error handling
 */
contract ErrorsRevertsSolutionTest is Test {
    ErrorsRevertsSolution public errors;
    
    address public owner;
    address public user1;
    
    function setUp() public {
        errors = new ErrorsRevertsSolution();
        owner = address(this);
        user1 = makeAddr("user1");
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR TESTS
    // ════════════════════════════════════════════════════════════════════════
    // INVARIANT: owner must be set at deployment. Failure = access control broken.

    function test_Constructor_SetsOwner() public {
        assertEq(errors.owner(), owner);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // require() TESTS
    // ════════════════════════════════════════════════════════════════════════
    // INVARIANT: Invalid inputs must revert. Failure = logic bug or missing validation.

    function test_DepositWithRequire_RevertsForZeroAmount() public {
        vm.expectRevert("Amount must be positive");
        errors.depositWithRequire(0);
    }
    
    function test_DepositWithRequire_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner");
        errors.depositWithRequire(100);
    }
    
    function test_DepositWithRequire_WorksForOwner() public {
        errors.depositWithRequire(100);
        assertEq(errors.getBalance(), 100);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // CUSTOM ERROR TESTS
    // ════════════════════════════════════════════════════════════════════════
    // INVARIANT: Custom errors must revert with correct selector. Failure = wrong error type.

    function test_DepositWithCustomError_RevertsForZeroAmount() public {
        vm.expectRevert(ErrorsRevertsSolution.InvalidAmount.selector);
        errors.depositWithCustomError(0);
    }
    
    function test_DepositWithCustomError_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ErrorsRevertsSolution.Unauthorized.selector, user1));
        errors.depositWithCustomError(100);
    }
    
    function test_DepositWithCustomError_WorksForOwner() public {
        errors.depositWithCustomError(100);
        assertEq(errors.getBalance(), 100);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // WITHDRAW TESTS
    // ════════════════════════════════════════════════════════════════════════
    // INVARIANT: Cannot withdraw more than balance. Failure = security issue (over-withdraw).

    function test_Withdraw_RevertsForInsufficientBalance() public {
        errors.depositWithCustomError(100);
        vm.expectRevert(abi.encodeWithSelector(ErrorsRevertsSolution.InsufficientBalance.selector, 100, 200));
        errors.withdraw(200);
    }
    
    function test_Withdraw_WorksWithSufficientBalance() public {
        errors.depositWithCustomError(100);
        errors.withdraw(50);
        assertEq(errors.getBalance(), 50);
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // assert() TESTS
    // ════════════════════════════════════════════════════════════════════════
    // INVARIANT: totalDeposits >= balance. Failure = internal inconsistency bug.

    function test_CheckInvariant_WorksWhenInvariantHolds() public {
        errors.depositWithCustomError(100);
        errors.checkInvariant(); // Should not revert
    }
    
    // ════════════════════════════════════════════════════════════════════════
    // GAS COMPARISON TESTS
    // ════════════════════════════════════════════════════════════════════════
    
    function test_Gas_CustomErrorVsRequire() public {
        uint256 gasBefore = gasleft();
        try errors.depositWithRequire(0) {} catch {}
        uint256 requireGas = gasBefore - gasleft();
        
        gasBefore = gasleft();
        try errors.depositWithCustomError(0) {} catch {}
        uint256 customErrorGas = gasBefore - gasleft();
        
        emit log_named_uint("Require gas", requireGas);
        emit log_named_uint("Custom error gas", customErrorGas);
        assertTrue(customErrorGas < requireGas, "Custom errors should use less gas");
    }
}
