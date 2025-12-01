function OptimizerConstantFoldingTestSuite() : TestSuite() constructor {

	// Test 1: Basic constant folding with addition
	addFact("Basic Constant Folding - Addition", function() {
	compile_and_execute(@'
		var result = 2 + 2;
		
		assert_equals(result, 4, "2 + 2 should fold into 4 at compile-time.");
		')
	});
		
	// Test 2: Constant folding with subtraction
	addFact("Constant Folding - Subtraction", function() {
	compile_and_execute(@'
		var result = 10 - 5;
		
		assert_equals(result, 5, "10 - 5 should fold into 5 at compile-time.");
		')
	});
		
	// Test 3: Constant folding with multiplication
	addFact("Constant Folding - Multiplication", function() {
	compile_and_execute(@'
		var result = 3 * 7;
		
		assert_equals(result, 21, "3 * 7 should fold into 21 at compile-time.");
		')
	});
		
	// Test 4: Constant folding with division
	addFact("Constant Folding - Division", function() {
	compile_and_execute(@'
		var result = 20 / 4;
		
		assert_equals(result, 5, "20 / 4 should fold into 5 at compile-time.");
		')
	});
	
	// Test 5: Constant folding with multiple operations in a complex expression
	addFact("Constant Folding - Multiple Operations", function() {
	compile_and_execute(@'
		var result = (5 + 3) * (2 + 4);
		
		assert_equals(result, 48, "The entire expression (5 + 3) * (2 + 4) should fold to 48.");
		')
	});
	
	// Test 6: Constant folding mixed with dynamic values
	addFact("Constant Folding with Dynamic Value", function() {
	compile_and_execute(@'
		/// @NoOp
		var dynamicValue = 0
		var result = dynamicValue + 2;
		
		assert_equals(result, 2, "Dynamic value should not allow constant folding, result should vary.");
		')
	});
	
	// Test 7: Constant folding for repeated constants
	addFact("Constant Folding for Repeated Constants", function() {
	compile_and_execute(@'
		var result = (10 + 5) + (10 + 5);
		
		assert_equals(result, 30, "The repeated constants should be folded together as 30.");
		')
	});
	
	// Test 8: Folding in a conditional expression
	addFact("Constant Folding in Conditional", function() {
	compile_and_execute(@'
		var result;
		if (5 > 3) {
			result = 10 + 5;
		}
		
		assert_equals(result, 15, "Condition is true and constant folding should reduce 10 + 5 to 15.");
		')
	});
	
	// Test 9: Constant folding on large numbers
	addFact("Constant Folding on Large Numbers", function() {
	compile_and_execute(@'
		var result = 1000000 * 3;
		
		assert_equals(result, 3000000, "Large number multiplication should fold correctly.");
		')
	});
	
	// Test 11: Constant folding with simple comparison
	addFact("Constant Folding with Comparison", function() {
	compile_and_execute(@'
		var result = (5 > 2) && (3 == 3);
		
		assert_equals(result, true, "The comparison (5 > 2) && (3 == 3) should fold to true.");
		')
	});
	
	// Test 12: Constant folding with modulo operation
	addFact("Constant Folding with Modulo", function() {
	compile_and_execute(@'
		var result = 10 mod 3;
		
		assert_equals(result, 1, "10 mod 3 should fold into 1 at compile-time.");
		')
	});
	
	// Test 13: Folding in combination with logical expressions
	addFact("Constant Folding with Logical Operations", function() {
	compile_and_execute(@'
		var result = true && false || true;
		
		assert_equals(result, true, "Logical expressions with constants should fold correctly to true.");
		')
	});
	
	// Test 14: No constant folding when using variables
	addFact("No Constant Folding with Variables", function() {
	compile_and_execute(@'
		var _x = 5;
		var result = _x + 10;
		
		assert_equals(result, 15, "Constant folding should not occur when variables are involved.");
		')
	})	
		
}