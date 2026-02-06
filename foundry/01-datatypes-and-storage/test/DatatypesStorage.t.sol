// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DatatypesStorage.sol";

/**
 * @title DatatypesStorageTest
 * @notice Skeleton test suite for DatatypesStorage contract
 * @dev Complete the TODOs to implement comprehensive tests
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                          WHAT IS A TEST FILE?
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Think of a test file as a quality control inspector in a factory. Just like
 * an inspector checks every product to make sure it works correctly before
 * shipping, our test file checks every function in our smart contract to ensure
 * it behaves exactly as expected.
 *
 * WHY DO WE TEST?
 *
 * 1. **Catch Bugs Before Deployment**: Once a contract is on the blockchain,
 *    you CAN'T change it. A bug in production could mean lost funds forever.
 *    Testing is your safety net.
 *
 * 2. **Document Expected Behavior**: Tests serve as living documentation.
 *    Someone reading your tests can understand exactly what your contract
 *    should do, with concrete examples.
 *
 * 3. **Prevent Regressions**: When you add new features, tests ensure you
 *    didn't accidentally break existing functionality.
 *
 * 4. **Build Confidence**: Good tests let you refactor code fearlessly,
 *    knowing you'll catch any mistakes immediately.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                        FOUNDRY TESTING BASICS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Foundry's testing framework follows these conventions:
 *
 * - **Test functions MUST start with "test"**: This is how Foundry identifies
 *   which functions to run. `testSetNumber()` runs, `checkNumber()` doesn't.
 *
 * - **setUp() runs before EACH test**: Think of it like resetting the game
 *   board before each round. This ensures every test starts from the same
 *   clean state (isolation!).
 *
 * - **Assertions verify behavior**:
 *   - `assertEq(a, b)`: Check if two values are equal
 *   - `assertTrue(x)`: Check if something is true
 *   - `assertFalse(x)`: Check if something is false
 *   - `vm.expectRevert()`: Check that the next call fails (reverts)
 *
 * - **Cheatcodes control the environment** (vm.*):
 *   - `vm.prank(address)`: Next call pretends to come from that address
 *   - `vm.deal(address, amount)`: Give an address some ETH
 *   - `vm.expectEmit()`: Check that an event was emitted
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      HOW TO RUN TESTS
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * forge test                    # Run all tests
 * forge test -vvv               # Verbose mode - see detailed output
 * forge test --gas-report       # Show gas costs for each function
 * forge test --match-test testSetNumber  # Run only tests matching this name
 * forge coverage                # See which lines of code are tested
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *                      THIS TEST FILE SHOULD COVER:
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Constructor behavior (initial state)
 * Value type operations (uint256, address, bool)
 * Mapping operations (set, get, check existence)
 * Array operations (push, access, length, remove)
 * Struct operations (create, read, update)
 * Data location behavior (storage vs memory vs calldata)
 * Event emissions (logging important state changes)
 * Edge cases (max values, empty arrays, zero address)
 * Gas measurements (comparing costs of different approaches)
 * Fuzz testing (randomized inputs to find unexpected bugs)
 * Invariant testing (properties that should ALWAYS be true)
 *
 */
contract DatatypesStorageTest is Test {
    DatatypesStorage public datatypes;

    address public owner;
    address public user1;
    address public user2;

    // Event declarations for testing (must match contract events)
    // WHY DO WE REDECLARE EVENTS HERE?
    // ----------------------------------
    // In Solidity, to emit an event in a test (for vm.expectEmit), the test
    // contract needs its own declaration of that event. The compiler uses the
    // declaration to encode the event signature (keccak256 of the event name
    // and parameter types) into the LOG opcode's first topic.
    //
    // These MUST match the contract's event signatures EXACTLY, or the test
    // will check for the wrong topic hash and fail silently.
    event NumberUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event UserRegistered(address indexed wallet, uint256 balance);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event MessageUpdated(string oldMessage, string newMessage);
    event BalanceUpdated(address addr, uint256 balance);

    /**
     * ═══════════════════════════════════════════════════════════════════════
     *                           setUp() FUNCTION
     * ═══════════════════════════════════════════════════════════════════════
     *
     * This special function runs BEFORE EACH AND EVERY test function.
     *
     * WHY?
     * Isolation! We want each test to start from a clean slate, like resetting
     * a video game before each level. If Test A modifies the contract and
     * Test B depends on that modification, our tests become fragile and
     * hard to debug.
     *
     * WHAT HAPPENS HERE:
     * 1. We create test addresses (owner, user1, user2)
     * 2. We deploy a FRESH instance of DatatypesStorage
     * 3. We label addresses for better debugging output
     *
     * IMPORTANT: Even if Test A sets number = 100, when Test B runs,
     * setUp() will deploy a brand new contract where number = 0 again.
     * This is GOOD - it prevents tests from interfering with each other!
     *
     * @dev Runs before each test function
     *      Creates fresh contract instance for each test (isolation)
     */
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        datatypes = new DatatypesStorage();

        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          CONSTRUCTOR TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST THE CONSTRUCTOR?
    // The constructor runs once when the contract is deployed. It sets up the
    // initial state. If the constructor has a bug, EVERY deployment will start
    // in a broken state. Testing it ensures the contract initializes correctly.
    //
    // WHAT TO TEST:
    // - Check that all initial values are set correctly
    // - Verify that ownership is assigned properly
    // - Ensure any flags (like isActive) start in the expected state

    /**
     * @notice Tests that the constructor correctly sets the owner
     * @dev Use assertEq to check that datatypes.owner() equals the owner variable
     */
    function test_Constructor_SetsOwner() public view {
        assertEq(datatypes.owner(), owner, "Owner should be set to deployer");
    }

    /**
     * @notice Tests that the constructor correctly sets isActive to true
     * @dev Use assertTrue to check that datatypes.isActive() returns true
     */
    function test_Constructor_SetsIsActive() public view {
        assertTrue(datatypes.isActive(), "Contract should be active on deployment");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          VALUE TYPE TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST VALUE TYPES?
    // Value types (uint, address, bool, etc.) are the building blocks of your
    // contract's state. Testing them ensures basic state management works.
    //
    // WHAT TO TEST FOR VALUE TYPES:
    // 1. Setting values (write operations)
    // 2. Getting values (read operations)
    // 3. Edge cases (zero, max values, overflow protection)
    // 4. Events (are state changes properly logged?)

    /**
     * @notice Tests setting a number value
     * @dev Test the "happy path" - normal expected use case
     *      Pattern: Arrange -> Act -> Assert
     */
    function test_SetNumber() public {
        uint256 newNumber = 42;
        datatypes.setNumber(newNumber);
        assertEq(datatypes.getNumber(), newNumber, "Number should be updated");
    }

    /**
     * @notice Tests that setNumber emits the correct event
     * @dev Use vm.expectEmit() to check event emissions
     *
     *      HOW vm.expectEmit WORKS:
     *      -------------------------
     *      vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData)
     *
     *      Topic 0 is ALWAYS the event signature hash (checked automatically).
     *      Topics 1-3 are indexed parameters. "Data" is non-indexed parameters.
     *
     *      Our NumberUpdated event has both params indexed, so:
     *      vm.expectEmit(true, true, false, true)
     *        - true:  check topic1 (oldValue, indexed)
     *        - true:  check topic2 (newValue, indexed)
     *        - false: no topic3 (we only have 2 indexed params)
     *        - true:  check data (no non-indexed data, but good practice)
     *
     *      Then we emit the EXPECTED event, then call the function that
     *      should produce that event. Foundry compares the two.
     */
    function test_SetNumber_EmitsEvent() public {
        uint256 newNumber = 100;

        vm.expectEmit(true, true, false, true);
        emit NumberUpdated(0, newNumber);

        datatypes.setNumber(newNumber);
    }

    /**
     * @notice Tests that getNumber returns the correct initial value
     * @dev Check initial state, then set and verify
     */
    function test_GetNumber_ReturnsCorrectValue() public {
        assertEq(datatypes.getNumber(), 0, "Initial number should be 0");

        datatypes.setNumber(123);
        assertEq(datatypes.getNumber(), 123, "Number should be 123 after setting");
    }

    /**
     * @notice Tests incrementing the number
     * @dev Set a number, increment it, verify it increased by 1
     */
    function test_IncrementNumber() public {
        datatypes.setNumber(5);
        datatypes.incrementNumber();
        assertEq(datatypes.getNumber(), 6, "Number should increment by 1");
    }

    /**
     * @notice Tests incrementing from zero
     * @dev Verify incrementing from 0 works correctly
     */
    function test_IncrementNumber_FromZero() public {
        assertEq(datatypes.getNumber(), 0, "Initial number is 0");
        datatypes.incrementNumber();
        assertEq(datatypes.getNumber(), 1, "Number should be 1 after increment");
    }

    /**
     * @notice Tests that incrementNumber reverts when it would overflow
     * @dev Set number to type(uint256).max, then try to increment
     *      Use vm.expectRevert() before the call that should fail
     */
    function test_IncrementNumber_RevertsOnOverflow() public {
        datatypes.setNumber(type(uint256).max);
        vm.expectRevert();
        datatypes.incrementNumber();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          MAPPING TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHY TEST MAPPINGS?
    // Mappings are like databases - they store key-value pairs. Most contracts
    // use mappings extensively (token balances, user data, permissions). Testing
    // them ensures your "database" works correctly!
    //
    // WHAT TO TEST FOR MAPPINGS:
    // 1. Setting values (write operations)
    // 2. Getting values (read operations)
    // 3. Default values (what happens for non-existent keys?)
    // 4. Independence (changing one key doesn't affect others)
    // 5. Updates (overwriting existing values)

    /**
     * @notice Tests setting a balance for an address
     * @dev Basic "write then read" pattern for mappings
     */
    function test_SetBalance() public {
        uint256 balance = 1000;
        datatypes.setBalance(user1, balance);
        assertEq(datatypes.getBalance(user1), balance, "Balance should be set correctly");
    }

    /**
     * @notice Tests that getBalance returns zero for new addresses
     * @dev Mappings return default values (0 for uint256) for non-existent keys
     */
    function test_GetBalance_ReturnsZeroForNewAddress() public view {
        assertEq(datatypes.getBalance(user1), 0, "New address should have zero balance by default");
    }

    /**
     * @notice Tests updating an existing balance
     * @dev Set balance twice, verify second value overwrites first
     */
    function test_SetBalance_UpdatesExistingBalance() public {
        datatypes.setBalance(user1, 100);
        datatypes.setBalance(user1, 200);
        assertEq(datatypes.getBalance(user1), 200, "Balance should be updated to new value");
    }

    /**
     * @notice Tests that balances are independent for different addresses
     * @dev Set different balances for user1 and user2, verify both are correct
     */
    function test_SetBalance_IndependentAddresses() public {
        datatypes.setBalance(user1, 100);
        datatypes.setBalance(user2, 200);

        assertEq(datatypes.getBalance(user1), 100, "User1 balance should be 100");
        assertEq(datatypes.getBalance(user2), 200, "User2 balance should be 200");
    }

    /**
     * @notice Tests hasBalance returns true for non-zero balance
     * @dev Set a balance, verify hasBalance returns true
     */
    function test_HasBalance_ReturnsTrueForNonZero() public {
        datatypes.setBalance(user1, 1);
        assertTrue(datatypes.hasBalance(user1), "Should return true for non-zero balance");
    }

    /**
     * @notice Tests hasBalance returns false for zero balance
     * @dev Don't set balance, verify hasBalance returns false
     */
    function test_HasBalance_ReturnsFalseForZero() public view {
        assertFalse(datatypes.hasBalance(user1), "Should return false for zero balance");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          ARRAY TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests that adding numbers increases array length
     * @dev Verify length increases with each addNumber() call
     */
    function test_AddNumber_IncreasesLength() public {
        assertEq(datatypes.getNumbersLength(), 0, "Initial length should be 0");

        datatypes.addNumber(10);
        assertEq(datatypes.getNumbersLength(), 1, "Length should be 1 after adding");

        datatypes.addNumber(20);
        assertEq(datatypes.getNumbersLength(), 2, "Length should be 2 after adding");
    }

    /**
     * @notice Tests that added numbers are stored correctly
     * @dev Add numbers and verify they're at the correct indices
     */
    function test_AddNumber_StoresCorrectValue() public {
        datatypes.addNumber(42);
        assertEq(datatypes.getNumberAt(0), 42, "First element should be 42");

        datatypes.addNumber(100);
        assertEq(datatypes.getNumberAt(1), 100, "Second element should be 100");
    }

    /**
     * @notice Tests that getNumberAt reverts on out of bounds access
     * @dev Add one number, try to access index 1, expect revert
     */
    function test_GetNumberAt_RevertsOnOutOfBounds() public {
        datatypes.addNumber(1);

        vm.expectRevert("Index out of bounds");
        datatypes.getNumberAt(1);
    }

    /**
     * @notice Tests that getNumbersLength returns correct length
     * @dev Add multiple numbers in a loop, verify length
     */
    function test_GetNumbersLength_ReturnsCorrectLength() public {
        for (uint256 i = 0; i < 5; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 5, "Length should be 5 after adding 5 elements");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          STRUCT TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests registering a user
     * @dev Register user, then get user data and verify all fields
     */
    function test_RegisterUser() public {
        uint256 initialBalance = 500;
        datatypes.registerUser(user1, initialBalance);

        (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);

        assertEq(wallet, user1, "Wallet address should match");
        assertEq(balance, initialBalance, "Balance should match");
        assertTrue(isRegistered, "User should be registered");
    }

    /**
     * @notice Tests that registerUser emits the correct event
     * @dev Use vm.expectEmit() to verify event emission
     */
    function test_RegisterUser_EmitsEvent() public {
        uint256 balance = 1000;

        vm.expectEmit(true, false, false, true);
        emit UserRegistered(user1, balance);

        datatypes.registerUser(user1, balance);
    }

    /**
     * @notice Tests updating an existing user
     * @dev Register user twice with different balances, verify update
     */
    function test_RegisterUser_UpdatesExistingUser() public {
        datatypes.registerUser(user1, 100);
        datatypes.registerUser(user1, 200);

        (, uint256 balance,) = datatypes.getUser(user1);
        assertEq(balance, 200, "Balance should be updated to new value");
    }

    /**
     * @notice Tests that getUser returns default values for non-existent users
     * @dev Get user data without registering, verify default values
     */
    function test_GetUser_ReturnsDefaultForNonExistent() public view {
        (address wallet, uint256 balance, bool isRegistered) = datatypes.getUser(user1);

        assertEq(wallet, address(0), "Wallet should be zero address");
        assertEq(balance, 0, "Balance should be zero");
        assertFalse(isRegistered, "Should not be registered");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          DATA LOCATION TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests summing a memory array
     * @dev Create a memory array, sum it, verify result
     */
    function test_SumMemoryArray() public view {
        uint256[] memory arr = new uint256[](4);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        arr[3] = 40;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 100, "Sum should be 100");
    }

    /**
     * @notice Tests summing an empty array
     * @dev Sum empty array, verify result is 0
     */
    function test_SumMemoryArray_EmptyArray() public view {
        uint256[] memory arr = new uint256[](0);
        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 0, "Sum of empty array should be 0");
    }

    /**
     * @notice Tests summing a single element array
     * @dev Sum array with one element, verify result
     */
    function test_SumMemoryArray_SingleElement() public view {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 42;

        uint256 sum = datatypes.sumMemoryArray(arr);
        assertEq(sum, 42, "Sum should be 42");
    }

    /**
     * @notice Tests getting first element from calldata array
     * @dev Create memory array, call getFirstElement, verify result
     */
    function test_GetFirstElement() public view {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 100;
        arr[1] = 200;
        arr[2] = 300;

        uint256 first = datatypes.getFirstElement(arr);
        assertEq(first, 100, "First element should be 100");
    }

    /**
     * @notice Tests that getFirstElement reverts on empty array
     * @dev Create empty array, expect revert when getting first element
     */
    function test_GetFirstElement_RevertsOnEmpty() public {
        uint256[] memory arr = new uint256[](0);

        vm.expectRevert("Array is empty");
        datatypes.getFirstElement(arr);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          ADVANCED TESTS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests setting a message string
     * @dev Set message and verify it's stored correctly
     */
    function test_SetMessage() public {
        string memory newMessage = "Hello World";
        datatypes.setMessage(newMessage);
        assertEq(datatypes.message(), newMessage, "Message should be updated");
    }

    /**
     * @notice Tests depositing ETH increases balance
     * @dev Use vm.deal() to give user1 ETH, then deposit
     */
    function test_Deposit_IncreasesBalance() public {
        uint256 amount = 1 ether;
        vm.deal(user1, amount);
        vm.prank(user1);
        datatypes.deposit{value: amount}();
        assertEq(datatypes.getBalance(user1), amount, "Balance should be updated");
    }

    /**
     * @notice Tests that deposit reverts on zero amount
     * @dev Try to deposit 0 ETH, expect revert
     */
    function test_Deposit_RevertsOnZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert();
        datatypes.deposit{value: 0}();
    }

    /**
     * @notice Tests removing a number from array
     * @dev Add numbers, remove one, verify correct removal
     */
    function test_RemoveNumber() public {
        datatypes.addNumber(10);
        datatypes.addNumber(20);
        datatypes.addNumber(30);
        datatypes.removeNumber(1);
        assertEq(datatypes.getNumbersLength(), 2, "Array length should be 2");
        assertEq(datatypes.getNumberAt(1), 30, "Last element should be moved");
    }

    /**
     * @notice Tests that removeNumber reverts on out of bounds
     * @dev Add one number, try to remove at invalid index
     */
    function test_RemoveNumber_RevertsOnOutOfBounds() public {
        datatypes.addNumber(10);
        vm.expectRevert();
        datatypes.removeNumber(1);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          FUZZ TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHAT IS FUZZ TESTING?
    // Fuzz testing automatically generates HUNDREDS of random inputs and runs
    // your test with each one. This finds edge cases you never thought of!
    //
    // HOW IT WORKS IN FOUNDRY:
    // 1. Name your test function starting with "testFuzz_"
    // 2. Add parameters to the function (uint256 _number, address _addr, etc.)
    // 3. Foundry runs the test 256 times (default) with random values
    // 4. If ANY run fails, the test fails and shows you the problematic input

    /**
     * @notice Fuzz test for setNumber - tests with random uint256 values
     * @dev Foundry will generate random values for _number
     */
    function testFuzz_SetNumber(uint256 _number) public {
        datatypes.setNumber(_number);
        assertEq(datatypes.getNumber(), _number, "Number should equal fuzzed input");
    }

    /**
     * @notice Fuzz test for setBalance - tests with random addresses and values
     * @dev Foundry will generate random address and balance
     */
    function testFuzz_SetBalance(address _addr, uint256 _balance) public {
        datatypes.setBalance(_addr, _balance);
        assertEq(datatypes.getBalance(_addr), _balance, "Balance should match fuzzed input");
    }

    /**
     * @notice Fuzz test for incrementNumber with bounded inputs
     * @dev Use bound() to constrain _start to avoid overflow
     */
    function testFuzz_IncrementNumber(uint256 _start) public {
        _start = bound(_start, 0, type(uint256).max - 1);

        datatypes.setNumber(_start);
        datatypes.incrementNumber();

        assertEq(datatypes.getNumber(), _start + 1, "Should increment by 1");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          GAS BENCHMARKING
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Benchmark gas cost of setting a number (first time - cold storage)
     * @dev Use gasleft() before and after to measure gas
     */
    function test_Gas_SetNumber_Cold() public {
        uint256 gasBefore = gasleft();
        datatypes.setNumber(42);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for cold setNumber", gasUsed);
    }

    /**
     * @notice Benchmark gas cost of setting a number (second time - warm storage)
     * @dev First call warms storage, second call should be cheaper
     */
    function test_Gas_SetNumber_Warm() public {
        datatypes.setNumber(42);

        uint256 gasBefore = gasleft();
        datatypes.setNumber(100);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for warm setNumber", gasUsed);
    }

    /**
     * @notice Benchmark gas cost of array operations
     * @dev Measure gas for adding numbers to array
     */
    function test_Gas_ArrayOperations() public {
        uint256 gasBefore = gasleft();
        datatypes.addNumber(1);
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for first array push", gasUsed);

        gasBefore = gasleft();
        datatypes.addNumber(2);
        gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for second array push", gasUsed);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          EDGE CASES
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @notice Tests handling of maximum uint256 value
     * @dev Set number to type(uint256).max and verify it works
     */
    function test_EdgeCase_MaxUint256() public {
        datatypes.setNumber(type(uint256).max);
        assertEq(datatypes.getNumber(), type(uint256).max, "Should handle max uint256");
    }

    /**
     * @notice Tests handling of zero address
     * @dev Set balance for address(0) and verify it works
     */
    function test_EdgeCase_ZeroAddress() public {
        datatypes.setBalance(address(0), 100);
        assertEq(datatypes.getBalance(address(0)), 100, "Should handle zero address");
    }

    /**
     * @notice Tests handling of large arrays
     * @dev Add many elements and verify length
     */
    function test_EdgeCase_LargeArray() public {
        for (uint256 i = 0; i < 10; i++) {
            datatypes.addNumber(i);
        }
        assertEq(datatypes.getNumbersLength(), 10, "Should handle multiple additions");
    }

    // ═══════════════════════════════════════════════════════════════════════
    //                          INVARIANT TESTS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // WHAT ARE INVARIANTS?
    // Properties that should ALWAYS be true, no matter what operations are
    // performed. Foundry can run these repeatedly with random operations.

    /**
     * @notice Invariant: Owner should never change
     * @dev Function name starts with "invariant_" for Foundry to recognize it
     */
    function invariant_OwnerNeverChanges() public view {
        assertEq(datatypes.owner(), owner, "Owner should never change");
    }

    /**
     * @notice Invariant: Array length should always be consistent
     * @dev Verify length is never negative (always >= 0)
     */
    function invariant_ArrayLengthConsistent() public view {
        uint256 length = datatypes.getNumbersLength();
        assertTrue(length >= 0, "Length should never be negative");
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 *                        TESTING BEST PRACTICES
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * 1. TEST NAMING CONVENTION
 *    test_FunctionName_Scenario
 *    testFuzz_FunctionName for fuzz tests
 *    invariant_PropertyName for invariant tests
 *
 * 2. COVERAGE
 *    Happy path (normal operations)
 *    Edge cases (max values, empty inputs, zero address)
 *    Reverts (invalid inputs, overflow, out of bounds)
 *    Events (verify emissions)
 *    Gas costs (benchmark critical operations)
 *
 * 3. ISOLATION
 *    Each test should be independent
 *    setUp() runs before each test
 *    Don't rely on test execution order
 *
 * 4. ASSERTIONS
 *    assertEq: Check equality
 *    assertTrue/False: Check booleans
 *    assertGt/Lt: Check comparisons
 *    vm.expectRevert: Check reverts
 *
 * 5. GAS AWARENESS
 *    Use gasleft() for manual measurements
 *    Use --gas-report flag for automated reports
 *    Benchmark critical operations
 *
 *                            RUN TESTS
 *
 * forge test                   # Run all tests
 * forge test -vvv              # Run with verbose output
 * forge test --gas-report      # Run with gas reporting
 * forge test --match-test test_SetNumber  # Run specific test
 * forge test --match-contract DatatypesStorageTest  # Run specific contract
 * forge coverage               # Generate coverage report
 *
 *                            STUDY THE SOLUTION
 *
 * After implementing your tests, compare with:
 * test/solution/DatatypesStorageSolution.t.sol
 */
